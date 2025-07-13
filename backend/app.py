from flask import Flask, request, jsonify
from flask_cors import CORS
import cv2
import numpy as np
import base64
import os
import uuid
from datetime import datetime
from skimage.metrics import structural_similarity as ssim
from werkzeug.utils import secure_filename
import tempfile
import shutil
import logging
from functools import wraps

app = Flask(__name__)
CORS(app)

# Configuration
UPLOAD_FOLDER = 'uploads'
RESULTS_FOLDER = 'results'
MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
MAX_RESOLUTION = 1500  # Reduced from 2000 to 1500 pixels

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create necessary folders
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RESULTS_FOLDER, exist_ok=True)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['RESULTS_FOLDER'] = RESULTS_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

# API Key (set via environment variable or default)
API_KEY = os.environ.get('API_KEY', 'your_secure_api_key')

def require_api_key(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        key = request.headers.get('X-API-Key')
        if not key or key != API_KEY:
            return jsonify({'success': False, 'error': 'Invalid API key'}), 403
        return f(*args, **kwargs)
    return decorated

class PreciseImageDifferenceDetector:
    def __init__(self):
        self.resize_method = cv2.INTER_LANCZOS4
        self.alignment_method = "phase"
    
    def set_alignment_method(self, method):
        self.alignment_method = method
        logger.info(f"Alignment method set to: {method}")
    
    def align_images_with_features(self, img1, img2):
        logger.info("Aligning with feature points...")
        gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
        gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)
        
        orb = cv2.ORB_create(nfeatures=5000)
        kp1, des1 = orb.detectAndCompute(gray1, None)
        kp2, des2 = orb.detectAndCompute(gray2, None)
        
        if des1 is None or des2 is None:
            logger.warning("Not enough feature points found!")
            return img1, img2
        
        bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
        matches = bf.match(des1, des2)
        
        if len(matches) < 10:
            logger.warning("Not enough matches found!")
            return img1, img2
        
        matches = sorted(matches, key=lambda x: x.distance)
        src_pts = np.float32([kp1[m.queryIdx].pt for m in matches[:100]]).reshape(-1, 1, 2)
        dst_pts = np.float32([kp2[m.trainIdx].pt for m in matches[:100]]).reshape(-1, 1, 2)
        
        M, mask = cv2.findHomography(src_pts, dst_pts, cv2.RANSAC, 5.0)
        
        if M is None:
            logger.warning("Cannot calculate transformation!")
            return img1, img2
        
        h, w = img2.shape[:2]
        img1_aligned = cv2.warpPerspective(img1, M, (w, h))
        angle = np.arctan2(M[1, 0], M[0, 0]) * 180 / np.pi
        logger.info(f"Detected rotation: {angle:.2f}°")
        
        return img1_aligned, img2
    
    def align_images_ecc(self, img1, img2):
        logger.info("Aligning with ECC...")
        gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
        gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)
        
        warp_mode = cv2.MOTION_EUCLIDEAN
        warp_matrix = np.eye(2, 3, dtype=np.float32)
        criteria = (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 50, 0.001)
        
        try:
            (cc, warp_matrix) = cv2.findTransformECC(gray1, gray2, warp_matrix, warp_mode, criteria)
            img1_aligned = cv2.warpAffine(img1, warp_matrix, (img2.shape[1], img2.shape[0]))
            angle = np.arctan2(warp_matrix[1, 0], warp_matrix[0, 0]) * 180 / np.pi
            logger.info(f"Detected rotation: {angle:.2f}°")
            logger.info(f"Correlation: {cc:.3f}")
            return img1_aligned, img2
        except cv2.error as e:
            logger.error(f"ECC error: {e}")
            return img1, img2
    
    def align_images_phase_correlation(self, img1, img2):
        logger.info("Aligning with phase correlation...")
        gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
        gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)
        
        shift, response = cv2.phaseCorrelate(np.float32(gray1), np.float32(gray2))
        logger.info(f"Detected shift: ({shift[0]:.2f}, {shift[1]:.2f})")
        logger.info(f"Quality: {response:.3f}")
        
        M = np.float32([[1, 0, shift[0]], [0, 1, shift[1]]])
        img1_aligned = cv2.warpAffine(img1, M, (img2.shape[1], img2.shape[0]))
        
        return img1_aligned, img2
    
    def align_images(self, img1, img2):
        if self.alignment_method == "features":
            return self.align_images_with_features(img1, img2)
        elif self.alignment_method == "ecc":
            return self.align_images_ecc(img1, img2)
        elif self.alignment_method == "phase":
            return self.align_images_phase_correlation(img1, img2)
        else:
            logger.warning("Unknown alignment method, no alignment")
            return img1, img2
    
    def resize_images_to_same_size(self, img1, img2, target_size=None):
        h1, w1 = img1.shape[:2]
        h2, w2 = img2.shape[:2]
        scale = min(MAX_RESOLUTION / max(h1, h2), MAX_RESOLUTION / max(w1, w2))
        if scale < 1:
            img1 = cv2.resize(img1, None, fx=scale, fy=scale, interpolation=self.resize_method)
            img2 = cv2.resize(img2, None, fx=scale, fy=scale, interpolation=self.resize_method)
        target_w = max(w1, w2) if target_size is None else target_size[0]
        target_h = max(h1, h2) if target_size is None else target_size[1]
        img1_resized = cv2.resize(img1, (target_w, target_h), interpolation=self.resize_method)
        img2_resized = cv2.resize(img2, (target_w, target_h), interpolation=self.resize_method)
        logger.info(f"Images resized to: {target_w}x{target_h}")
        return img1_resized, img2_resized
    
    def create_superposition(self, img1, img2, alpha=0.5):
        img1_float = img1.astype(np.float32)
        img2_float = img2.astype(np.float32)
        superposition = cv2.addWeighted(img1_float, alpha, img2_float, 1-alpha, 0)
        superposition = np.clip(superposition, 0, 255).astype(np.uint8)
        return superposition
    
    def detect_differences_precise(self, img1, img2, sensitivity=25, min_area=30):
        logger.info(f"Detection with threshold: {sensitivity}, min area: {min_area}")
        gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
        gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)
        gray1 = cv2.GaussianBlur(gray1, (3, 3), 0)
        gray2 = cv2.GaussianBlur(gray2, (3, 3), 0)
        diff = cv2.absdiff(gray1, gray2)
        _, thresh = cv2.threshold(diff, sensitivity, 255, cv2.THRESH_BINARY)
        kernel = np.ones((3, 3), np.uint8)
        thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel, iterations=2)
        thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel, iterations=1)
        thresh = cv2.medianBlur(thresh, 5)
        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        valid_contours = [c for c in contours if cv2.contourArea(c) > min_area and
                         4 * np.pi * cv2.contourArea(c) / (cv2.arcLength(c, True) ** 2) > 0.1]
        return valid_contours, thresh, diff
    
    def draw_differences_on_images(self, img1, img2, contours):
        img1_marked = img1.copy()
        img2_marked = img2.copy()
        for i, contour in enumerate(contours):
            x, y, w, h = cv2.boundingRect(contour)
            cv2.rectangle(img1_marked, (x, y), (x + w, y + h), (0, 0, 255), 2)
            cv2.rectangle(img2_marked, (x, y), (x + w, y + h), (0, 0, 255), 2)
            cv2.putText(img1_marked, str(i+1), (x, y-10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2)
            cv2.putText(img2_marked, str(i+1), (x, y-10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2)
        return img1_marked, img2_marked
    
    def process_images_from_files(self, image1_path, image2_path, sensitivity=25, min_area=30, align=True):
        logger.info("=== STARTING PROCESS WITH ALIGNMENT ===")
        img1 = cv2.imread(image1_path)
        img2 = cv2.imread(image2_path)
        if img1 is None or img2 is None:
            raise ValueError("Cannot load images. Check paths.")
        logger.info(f"Image 1: {img1.shape}")
        logger.info(f"Image 2: {img2.shape}")
        img1_resized, img2_resized = self.resize_images_to_same_size(img1, img2)
        if align:
            logger.info(f"3. Aligning images (method: {self.alignment_method})...")
            img1_aligned, img2_aligned = self.align_images(img1_resized, img2_resized)
        else:
            logger.info("3. No alignment (disabled)")
            img1_aligned, img2_aligned = img1_resized, img2_resized
        superposition = self.create_superposition(img1_aligned, img2_aligned, alpha=0.5)
        contours, thresh, diff = self.detect_differences_precise(img1_aligned, img2_aligned, sensitivity, min_area)
        logger.info(f"Number of differences detected: {len(contours)}")
        img1_marked, img2_marked = self.draw_differences_on_images(img1_aligned, img2_aligned, contours)
        superposition_marked = self.create_superposition(img1_marked, img2_marked, alpha=0.5)
        gray1 = cv2.cvtColor(img1_aligned, cv2.COLOR_BGR2GRAY)
        gray2 = cv2.cvtColor(img2_aligned, cv2.COLOR_BGR2GRAY)
        similarity = ssim(gray1, gray2)
        total_pixels = gray1.shape[0] * gray1.shape[1]
        diff_pixels = np.sum(thresh > 0)
        difference_percentage = (diff_pixels / total_pixels) * 100
        logger.info(f"Similarity score: {similarity:.3f}")
        logger.info(f"Difference percentage: {difference_percentage:.2f}%")
        logger.info("=== PROCESS COMPLETE ===")
        return {
            'img1_original': img1_aligned,
            'img2_original': img2_aligned,
            'img1_marked': img1_marked,
            'img2_marked': img2_marked,
            'superposition': superposition,
            'superposition_marked': superposition_marked,
            'difference_map': diff,
            'threshold_map': thresh,
            'num_differences': len(contours),
            'similarity': similarity,
            'difference_percentage': difference_percentage,
            'contours': contours,
            'alignment_method': self.alignment_method
        }

def image_to_base64(image, quality=85):
    """Convert image to base64 with compression"""
    _, buffer = cv2.imencode('.jpg', image, [cv2.IMWRITE_JPEG_QUALITY, quality])
    return base64.b64encode(buffer).decode('utf-8')

def allowed_file(filename):
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'tiff'}
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def index():
    return jsonify({
        'message': 'EXTNOT Image Comparison API',
        'version': '1.0.0',
        'status': 'running',
        'endpoints': {
            'POST /compare_images': 'Compare two images and detect differences',
            'GET /health': 'Health check endpoint'
        }
    })

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'EXTNOT Image Comparison API'
    })

@app.route('/compare_images', methods=['POST'])
@require_api_key
def compare_images():
    try:
        logger.info(f"Request: POST /compare_images from {request.remote_addr}")
        if 'image1' not in request.files or 'image2' not in request.files:
            logger.error("Missing image files")
            return jsonify({
                'success': False,
                'error': 'Both image1 and image2 files are required',
                'details': 'Ensure both files are uploaded'
            }), 400
        
        image1_file = request.files['image1']
        image2_file = request.files['image2']
        
        if image1_file.filename == '' or image2_file.filename == '':
            logger.error("Empty filenames")
            return jsonify({
                'success': False,
                'error': 'Both files must have valid filenames',
                'details': 'Check file names'
            }), 400
        
        if not (allowed_file(image1_file.filename) and allowed_file(image2_file.filename)):
            logger.error("Invalid file types")
            return jsonify({
                'success': False,
                'error': 'Invalid file type. Allowed types: png, jpg, jpeg, gif, bmp, tiff',
                'details': 'Upload supported image formats'
            }), 400
        
        analysis_id = str(uuid.uuid4())
        logger.info(f"Analysis ID: {analysis_id}")
        temp_dir = os.path.join(app.config['UPLOAD_FOLDER'], analysis_id)
        os.makedirs(temp_dir, exist_ok=True)
        
        try:
            image1_path = os.path.join(temp_dir, secure_filename(image1_file.filename))
            image2_path = os.path.join(temp_dir, secure_filename(image2_file.filename))
            image1_file.save(image1_path)
            image2_file.save(image2_path)
            logger.info(f"Images saved: {image1_path}, {image2_path}")
            
            sensitivity = int(request.form.get('sensitivity', 25))
            min_area = int(request.form.get('min_area', 30))
            align = request.form.get('align', 'true').lower() == 'true'
            alignment_method = request.form.get('alignment_method', 'phase')
            logger.info(f"Parameters: sensitivity={sensitivity}, min_area={min_area}, align={align}, method={alignment_method}")
            
            detector = PreciseImageDifferenceDetector()
            detector.set_alignment_method(alignment_method)
            results = detector.process_images_from_files(image1_path, image2_path, sensitivity, min_area, align)
            
            # OPTIMIZED: Return only the 3 most important images with higher compression
            response_data = {
                'success': True,
                'analysis_id': analysis_id,
                'timestamp': datetime.now().isoformat(),
                'results': {
                    'original_image1': image_to_base64(results['img1_original'], quality=75),
                    'original_image2': image_to_base64(results['img2_original'], quality=75),
                    'difference_image': image_to_base64(results['superposition_marked'], quality=80),
                    'num_differences': results['num_differences'],
                    'similarity': float(results['similarity']),
                    'difference_percentage': float(results['difference_percentage']),
                    'alignment_method': results['alignment_method']
                },
                'parameters': {
                    'sensitivity': sensitivity,
                    'min_area': min_area,
                    'align': align,
                    'alignment_method': alignment_method
                }
            }
            
            # Log response size
            import json
            response_size = len(json.dumps(response_data)) / (1024 * 1024)
            logger.info(f"Response size: {response_size:.2f} MB")
            
            logger.info("Image comparison completed successfully")
            return jsonify(response_data)
            
        except Exception as e:
            logger.error(f"Error processing images: {e}")
            return jsonify({
                'success': False,
                'error': str(e),
                'details': 'Check image format, size, or server status'
            }), 500
            
        finally:
            try:
                if os.path.exists(temp_dir):
                    shutil.rmtree(temp_dir)
                    logger.info(f"Cleaned up temporary directory: {temp_dir}")
            except Exception as e:
                logger.error(f"Error cleaning up temporary files: {e}")
    
    except Exception as e:
        logger.error(f"Unexpected error in compare_images: {e}")
        return jsonify({
            'success': False,
            'error': f'Unexpected error: {str(e)}',
            'details': 'Contact administrator if issue persists'
        }), 500

@app.errorhandler(413)
def too_large(e):
    return jsonify({
        'success': False,
        'error': 'File too large. Maximum size is 16MB per file.'
    }), 413

@app.errorhandler(500)
def internal_error(e):
    logger.error(f"Internal server error: {e}")
    return jsonify({
        'success': False,
        'error': 'Internal server error. Please try again later.'
    }), 500

@app.before_request
def log_request():
    logger.info(f"Request: {request.method} {request.url} from {request.remote_addr}")

if __name__ == '__main__':
    print("=" * 60)
    print("EXTNOT Image Comparison Backend Starting...")
    print("=" * 60)
    print(f"Upload folder: {UPLOAD_FOLDER}")
    print(f"Results folder: {RESULTS_FOLDER}")
    print(f"Max file size: {MAX_CONTENT_LENGTH / (1024*1024):.1f}MB")
    print(f"Max resolution: {MAX_RESOLUTION}x{MAX_RESOLUTION} pixels")
    print("=" * 60)
    print("API Endpoints:")
    print("  GET  /           - API information")
    print("  GET  /health     - Health check")
    print("  POST /compare_images - Compare two images")
    print("=" * 60)
    print("Connection URLs:")
    print("  Local:           http://localhost:5000")
    print("  Android Emulator: http://10.0.2.2:5000")
    print("  iOS Simulator:   http://localhost:5000")
    print("  Network:         http://YOUR_IP:5000")
    print("=" * 60)
    app.run(debug=True, host='0.0.0.0', port=5000)