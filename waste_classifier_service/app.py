import os
import tempfile
import requests
from flask import Flask, request, jsonify
from PIL import Image
import numpy as np
import tensorflow as tf
import pickle

app = Flask(__name__)

# --- Model and Encoder Loading ---
# Construct paths relative to the app.py file
MODEL_DIR = os.path.join(os.path.dirname(__file__), 'ml_models')
MODEL_PATH = os.path.join(MODEL_DIR, 'waste_classifier_cnn.h5')
ENCODER_PATH = os.path.join(MODEL_DIR, 'waste_encoder.pkl')

model = None
encoder = None
class_labels = ['ErrorLoadingModelOrEncoder'] # Default

try:
    if os.path.exists(MODEL_PATH):
        model = tf.keras.models.load_model(MODEL_PATH)
        print("Successfully loaded Keras model.")
    else:
        print(f"Model file not found at: {MODEL_PATH}")

    if os.path.exists(ENCODER_PATH):
        with open(ENCODER_PATH, 'rb') as f:
            encoder = pickle.load(f)
        # Attempt to get class labels from the encoder
        # This assumes your encoder (e.g., LabelEncoder) has a 'classes_' attribute
        if hasattr(encoder, 'classes_'):
            class_labels = encoder.classes_.tolist() # Convert to list if it's a numpy array
            print(f"Successfully loaded encoder. Classes: {class_labels}")
        else:
            # Fallback if encoder.classes_ is not available or if it's a different type of encoder
            # YOU MUST PROVIDE YOUR ACTUAL CLASS LABELS HERE IN THE CORRECT ORDER
            # This is a placeholder.
            class_labels = ['paper', 'plastic', 'metal', 'glass', 'organic', 'trash']
            print(f"Encoder loaded, but 'classes_' attribute not found. Using predefined labels: {class_labels}")
    else:
        print(f"Encoder file not found at: {ENCODER_PATH}")
        # If encoder is critical and not found, you might want to prevent the app from fully starting
        # or handle predictions differently. For now, using placeholder labels.
        class_labels = ['paper', 'plastic', 'metal', 'glass', 'organic', 'trash'] # Placeholder
        print(f"Using predefined labels due to missing encoder: {class_labels}")


except Exception as e:
    print(f"FATAL: Error loading model or encoder: {e}")
    # In a real scenario, you might want to prevent the app from starting
    # or have more robust error handling here.
    model = None # Ensure model is None if loading failed
    encoder = None # Ensure encoder is None

# --- Image Preprocessing ---
# YOU MUST ADJUST THESE VALUES TO MATCH YOUR MODEL'S REQUIREMENTS
IMG_HEIGHT = 224  # Example, adjust to your model's expected input height
IMG_WIDTH = 224   # Example, adjust to your model's expected input width

def preprocess_image_from_path(image_path):
    """Loads and preprocesses an image from a file path."""
    try:
        img = Image.open(image_path).convert('RGB')
        img = img.resize((IMG_WIDTH, IMG_HEIGHT))
        img_array = tf.keras.preprocessing.image.img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0)  # Create a batch

        # Normalize if your model expects it (e.g., / 255.0)
        # This depends on how your model was trained.
        # Example: img_array = img_array / 255.0
        return img_array
    except Exception as e:
        print(f"Error preprocessing image from path: {e}")
        return None

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "message": "Waste classification service is running."}), 200

@app.route('/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({"error": "Model not loaded on server."}), 500
    
    data = request.get_json()
    if not data:
        return jsonify({"error": "No JSON data received."}), 400

    image_url = data.get('imageUrl')
    # TODO: Add support for base64 encoded image string if needed
    # image_b64 = data.get('imageBase64')

    if not image_url: # and not image_b64:
        return jsonify({"error": "Missing 'imageUrl' in JSON payload."}), 400

    tmp_file_path = None
    try:
        if image_url:
            # Download the image
            response = requests.get(image_url, stream=True, timeout=10) # Added timeout
            response.raise_for_status()

            # Save to a temporary file
            with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp_file:
                for chunk in response.iter_content(chunk_size=8192):
                    tmp_file.write(chunk)
                tmp_file_path = tmp_file.name
            
            print(f"Image downloaded to temporary path: {tmp_file_path}")
            processed_image = preprocess_image_from_path(tmp_file_path)
        # elif image_b64:
            # Handle base64 image processing here
            # processed_image = preprocess_image_from_base64(image_b64)
            # pass
        else: # Should not happen due to check above
            return jsonify({"error": "No image data provided."}), 400


        if processed_image is None:
            return jsonify({"error": "Failed to preprocess image."}), 500

        # Make prediction
        predictions = model.predict(processed_image)
        
        predicted_class_index = np.argmax(predictions[0])
        
        if 0 <= predicted_class_index < len(class_labels):
            predicted_label = class_labels[predicted_class_index]
        else:
            predicted_label = "Unknown" # Fallback if index is out of bounds

        confidence = float(predictions[0][predicted_class_index])

        print(f"Prediction: {predicted_label}, Confidence: {confidence:.4f}")
        
        return jsonify({
            "classification": predicted_label,
            "confidence": confidence
        })

    except requests.exceptions.RequestException as e:
        print(f"Error downloading image: {e}")
        return jsonify({"error": f"Error downloading image: {str(e)}"}), 500
    except tf.errors.OpError as e: # Catch TensorFlow specific errors during prediction
        print(f"TensorFlow OpError during prediction: {e}")
        return jsonify({"error": f"TensorFlow error during prediction: {str(e)}"}), 500
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"error": f"An unexpected error occurred on the server: {str(e)}"}), 500
    finally:
        if tmp_file_path and os.path.exists(tmp_file_path):
            try:
                os.remove(tmp_file_path)
                print(f"Temporary file {tmp_file_path} removed.")
            except Exception as e_rm:
                print(f"Error removing temporary file {tmp_file_path}: {e_rm}")


if __name__ == '__main__':
    # For local development. Gunicorn will be used in Docker.
    port = int(os.environ.get('PORT', 8080))
    app.run(debug=True, host='0.0.0.0', port=port)
