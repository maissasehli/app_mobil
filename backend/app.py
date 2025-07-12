from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from PIL import Image, ImageChops
import io
import base64
import os
from werkzeug.utils import secure_filename
import uuid

app = Flask(__name__)
CORS(app)

# Configuration
UPLOAD_FOLDER = 'uploads'
RESULTS_FOLDER = 'results'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp'}

# Créer les dossiers s'ils n'existent pas
for folder in [UPLOAD_FOLDER, RESULTS_FOLDER]:
    if not os.path.exists(folder):
        os.makedirs(folder)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def image_to_base64(image):
    """Convertir une image PIL en base64"""
    buffered = io.BytesIO()
    image.save(buffered, format="PNG")
    img_str = base64.b64encode(buffered.getvalue()).decode()
    return img_str

@app.route('/', methods=['GET'])
def index():
    """Page d'accueil pour vérifier que le serveur fonctionne"""
    return jsonify({
        "message": "Flask Image Comparison API",
        "status": "running",
        "endpoints": {
            "health": "/health",
            "compare": "/compare_images",
            "get_diff": "/get_difference/<analysis_id>",
            "cleanup": "/cleanup/<analysis_id>"
        }
    })

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "message": "Backend is running"})

@app.route('/compare_images', methods=['POST'])
def compare_images():
    try:
        # Vérifier si les deux images sont présentes
        if 'image1' not in request.files or 'image2' not in request.files:
            return jsonify({
                "error": "Both image1 and image2 are required",
                "success": False
            }), 400

        file1 = request.files['image1']
        file2 = request.files['image2']
        
        # Vérifier si les fichiers sont valides
        if file1.filename == '' or file2.filename == '':
            return jsonify({
                "error": "No files selected",
                "success": False
            }), 400
            
        if not (allowed_file(file1.filename) and allowed_file(file2.filename)):
            return jsonify({
                "error": "Invalid file format. Allowed formats: png, jpg, jpeg, gif, bmp",
                "success": False
            }), 400

        # Générer des noms de fichiers uniques
        unique_id = str(uuid.uuid4())
        filename1 = f"{unique_id}_image1_{secure_filename(file1.filename)}"
        filename2 = f"{unique_id}_image2_{secure_filename(file2.filename)}"
        
        # Sauvegarder les fichiers
        filepath1 = os.path.join(UPLOAD_FOLDER, filename1)
        filepath2 = os.path.join(UPLOAD_FOLDER, filename2)
        
        file1.save(filepath1)
        file2.save(filepath2)
        
        # Ouvrir les images avec PIL
        image1 = Image.open(filepath1).convert('RGB')
        image2 = Image.open(filepath2).convert('RGB')
        
        # Redimensionner les images pour qu'elles aient la même taille
        # Prendre la taille minimale entre les deux images
        min_width = min(image1.width, image2.width)
        min_height = min(image1.height, image2.height)
        
        image1 = image1.resize((min_width, min_height), Image.Resampling.LANCZOS)
        image2 = image2.resize((min_width, min_height), Image.Resampling.LANCZOS)
        
        # Calculer la différence entre les deux images
        diff = ImageChops.difference(image1, image2)
        
        # Améliorer la visibilité de la différence
        # Multiplier par un facteur pour rendre les différences plus visibles
        enhanced_diff = ImageChops.multiply(diff, 3)
        
        # Convertir en base64 pour l'envoi
        diff_base64 = image_to_base64(enhanced_diff)
        original1_base64 = image_to_base64(image1)
        original2_base64 = image_to_base64(image2)
        
        # Sauvegarder l'image de différence
        diff_filename = f"{unique_id}_difference.png"
        diff_filepath = os.path.join(RESULTS_FOLDER, diff_filename)
        enhanced_diff.save(diff_filepath)
        
        # Calculer quelques statistiques
        # Convertir la différence en niveaux de gris pour les calculs
        diff_gray = diff.convert('L')
        histogram = diff_gray.histogram()
        
        # Calculer le pourcentage de différence
        total_pixels = diff_gray.width * diff_gray.height
        different_pixels = total_pixels - histogram[0]  # Pixels non-noirs
        difference_percentage = (different_pixels / total_pixels) * 100
        
        # Nettoyer les fichiers temporaires
        try:
            os.remove(filepath1)
            os.remove(filepath2)
        except OSError:
            pass  # Ignorer si les fichiers n'existent pas
        
        return jsonify({
            "success": True,
            "message": "Images compared successfully",
            "results": {
                "difference_image": diff_base64,
                "original_image1": original1_base64,
                "original_image2": original2_base64,
                "difference_percentage": round(difference_percentage, 2),
                "image_dimensions": {
                    "width": min_width,
                    "height": min_height
                },
                "analysis_id": unique_id
            }
        })
        
    except Exception as e:
        return jsonify({
            "error": f"An error occurred: {str(e)}",
            "success": False
        }), 500

@app.route('/get_difference/<analysis_id>', methods=['GET'])
def get_difference_image(analysis_id):
    """Endpoint pour récupérer l'image de différence sauvegardée"""
    try:
        diff_filename = f"{analysis_id}_difference.png"
        diff_filepath = os.path.join(RESULTS_FOLDER, diff_filename)
        
        if os.path.exists(diff_filepath):
            return send_file(diff_filepath, mimetype='image/png')
        else:
            return jsonify({
                "error": "Difference image not found",
                "success": False
            }), 404
            
    except Exception as e:
        return jsonify({
            "error": f"An error occurred: {str(e)}",
            "success": False
        }), 500

@app.route('/cleanup/<analysis_id>', methods=['DELETE'])
def cleanup_analysis(analysis_id):
    """Nettoyer les fichiers d'une analyse"""
    try:
        diff_filename = f"{analysis_id}_difference.png"
        diff_filepath = os.path.join(RESULTS_FOLDER, diff_filename)
        
        if os.path.exists(diff_filepath):
            os.remove(diff_filepath)
            
        return jsonify({
            "success": True,
            "message": "Analysis files cleaned up successfully"
        })
        
    except Exception as e:
        return jsonify({
            "error": f"An error occurred: {str(e)}",
            "success": False
        }), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "error": "Endpoint not found",
        "success": False
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        "error": "Internal server error",
        "success": False
    }), 500

if __name__ == '__main__':
    print("Starting Flask server...")
    print("Available endpoints:")
    print("- GET / - API information")
    print("- GET /health - Health check")
    print("- POST /compare_images - Compare two images")
    print("- GET /get_difference/<analysis_id> - Get difference image")
    print("- DELETE /cleanup/<analysis_id> - Cleanup analysis files")
    print(f"Server running on: http://127.0.0.1:5000")
    
    # Essayer différents ports si 5000 est occupé
    port = 5000
    while True:
        try:
            app.run(debug=True, host='127.0.0.1', port=port)
            break
        except OSError as e:
            if "Address already in use" in str(e):
                port += 1
                print(f"Port {port-1} is busy, trying port {port}")
                if port > 5010:
                    print("Unable to find an available port")
                    break
            else:
                raise e