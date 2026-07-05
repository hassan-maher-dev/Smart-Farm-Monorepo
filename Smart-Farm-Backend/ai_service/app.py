"""
app.py (معدّل)
--------------
التعديل الوحيد عن النسخة القديمة هو:
- تنظيف اسم الكلاس من prefix "Tomato___" قبل إرجاعه
  (الموديل الجديد اتدرب على فولدرات اسمها Tomato___Bacterial_spot مثلاً،
   فالـ label الخارج هيكون بنفس الاسم، وعايزين نرجع "Bacterial_spot" بس للتطبيق)

باقي الكود مش اتغير — نفس الـ endpoint، نفس الـ response format،
نفس الـ preprocessing. التطبيق Flutter والويب مش محتاجين أي تعديل.
"""

import os
import numpy as np
from flask import Flask, request, jsonify
from PIL import Image
import tflite_runtime.interpreter as tflite

app = Flask(__name__)

# ============================================================
# Load Model
# ============================================================
MODEL_PATH = "model/model.tflite"
LABELS_PATH = "model/labels.txt"

interpreter = tflite.Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()
input_details  = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Load Labels
with open(LABELS_PATH, 'r') as f:
    labels = [line.strip() for line in f.readlines() if line.strip()]

print(f"✅ Model loaded | Classes: {len(labels)} | Labels: {labels}")

# ============================================================
# Helper: تنظيف اسم الكلاس من prefix "Tomato___"
# ============================================================
def clean_label(label: str) -> str:
    """
    بيحوّل "Tomato___Bacterial_spot" لـ "Bacterial_spot"
    ولو الاسم مش فيه prefix، يرجعه زي ما هو.
    """
    return label.replace("Tomato___", "").strip()

# ============================================================
# Helper: Preprocessing
# ============================================================
def preprocess_image(image_bytes):
    img = Image.open(image_bytes).convert('RGB')
    img = img.resize((224, 224))
    img_array = np.array(img, dtype=np.float32)
    img_array = np.expand_dims(img_array, axis=0)
    return img_array

# ============================================================
# Endpoints
# ============================================================
@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    try:
        input_data = preprocess_image(file)

        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])[0]

        max_index   = np.argmax(output_data)
        max_score   = output_data[max_index]
        raw_label   = labels[max_index]

        # ✅ التعديل الوحيد: تنظيف الاسم قبل الإرسال
        predicted_label = clean_label(raw_label)

        return jsonify({
            "diseaseLabel": predicted_label,
            "confidence": round(float(max_score) * 100, 1)
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
