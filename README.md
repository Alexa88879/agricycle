# AgriCycle ♻️ 🚜

**AgriCycle** is a mobile application built with Flutter that aims to revolutionize agricultural waste management. It provides a platform for farmers to connect with businesses, enabling the efficient sale, purchase, and recycling of agricultural waste. The app also features market trend analysis for agricultural commodities and an AI-powered waste classification tool.

## 🌟 Key Features

* **User Roles:** Separate interfaces and functionalities for Farmers and Businesses (Companies).
* **Waste Listing:** Farmers can list their agricultural waste products with details like type, quantity, location, and images.
* **Browse & Discover:** Businesses can browse and search for available waste listings.
* **Direct Connection:** Facilitates communication or contact between farmers and interested businesses (details on implementation may vary).
* **AI Waste Classification:** Users can upload images of waste, and an AI model (Python backend) classifies the type of waste.
* **Market Trends:** Provides insights into market prices and trends for various agricultural products to help farmers and businesses make informed decisions.
* **User Authentication:** Secure login and registration system using Firebase.
* **Dashboard:** Personalized dashboards for farmers and businesses to manage their listings, activities, and view relevant information.
* **My Listings:** Farmers can view and manage the waste they have listed.

## 📸 Screenshots (Placeholder)

*(It's highly recommended to add screenshots of your application here to give users a visual understanding of the app.)*

* *Login/Signup Screen*
* *Role Selection Screen*
* *Farmer Dashboard*
* *Company Dashboard*
* *New Waste Listing Screen*
* *Browse Listings Screen*
* *Listing Detail Screen*
* *Waste Classification Screen*
* *Market Trends Screen*

## 🛠️ Tech Stack

* **Frontend (Mobile App):**
    * Flutter & Dart
    * Provider (for state management)
    * Firebase SDKs (Auth, Firestore, Storage)
    * `http` (for network requests to the backend)
    * `image_picker` (for selecting images)
    * `fl_chart` (for displaying market trend charts)
* **Backend (Waste Classification Service):**
    * Python
    * Flask (for creating the API)
    * TensorFlow/Keras (or other ML library for the classification model - *inferred*)
    * Pillow (for image manipulation)
* **Database & Backend Services:**
    * Firebase Firestore (for data storage)
    * Firebase Authentication (for user management)
    * Firebase Storage (for storing images)

## 🚀 Getting Started

### Prerequisites

* Flutter SDK: [Install Flutter](https://flutter.dev/docs/get-started/install)
* Firebase Account: [Create a Firebase project](https://firebase.google.com/)
* Python environment for the backend service.
* An editor like VS Code or Android Studio.

### Frontend Setup (Flutter App)

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/your-username/agricycle.git](https://github.com/your-username/agricycle.git)
    cd agricycle
    ```
2.  **Set up Firebase:**
    * Create a new Firebase project.
    * Add an Android and/or iOS app to your Firebase project.
    * Download the `google-services.json` file for Android and place it in `android/app/`.
    * Download the `GoogleService-Info.plist` file for iOS and place it in `ios/Runner/`.
    * Enable Firebase Authentication (Email/Password).
    * Set up Firebase Firestore and Firebase Storage with appropriate security rules. (Refer to `firebase_rules/` for examples, but ensure they are secure for production).

3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

4.  **Run the app:**
    ```bash
    flutter run
    ```

### Backend Setup (Waste Classifier Service)

1.  **Navigate to the service directory:**
    ```bash
    cd waste_classifier_service
    ```
2.  **Create a virtual environment (recommended):**
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    ```
3.  **Install Python dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
4.  **Prepare your Machine Learning Model:**
    * The `app.py` expects a trained model file (e.g., `waste_model.h5` or similar). You'll need to train your waste classification model and place it in the `waste_classifier_service` directory or update the path in `app.py`.
    * Ensure you have a `labels.txt` file if your model requires one for class names.

5.  **Run the Flask server:**
    ```bash
    python app.py
    ```
    By default, it might run on `http://127.0.0.1:5000`.

6.  **Configure Flutter App to connect to Backend:**
    * In your Flutter code (likely in `lib/screens/waste_classification_screen.dart` or a service file), update the API endpoint to point to your running Flask server. If running on a local machine and testing with an emulator/device, you might need to use your machine's local IP address instead of `127.0.0.1`. For Android emulators, `10.0.2.2` usually maps to the host machine's localhost.

## 💡 How to Use

1.  **Sign Up/Login:** Create an account or log in if you already have one.
2.  **Select Role:** Choose whether you are a "Farmer" or a "Company/Business".
3.  **Farmer Dashboard:**
    * **Post Waste:** Create new listings for agricultural waste, providing details and images.
    * **My Listings:** View and manage your active listings.
    * **Market Trends:** Check current market prices for various commodities.
    * **Classify Waste:** Use the AI tool to identify types of waste.
4.  **Company Dashboard:**
    * **Browse Listings:** Search and view waste listings posted by farmers.
    * **View Details:** Get more information about specific listings.
    * **Market Trends:** Analyze market data.
    * **Classify Waste:** Utilize the AI waste classification tool.

## 🔮 Future Enhancements

* **In-App Chat/Messaging:** Direct communication between farmers and businesses.
* **Bidding System:** Allow businesses to bid on waste listings.
* **Logistics Integration:** Options for transportation or pickup services.
* **Advanced Analytics:** More detailed market trend analysis and reporting.
* **Notifications:** Real-time alerts for new listings, messages, or bids.
* **Payment Integration:** Secure payment processing for transactions.
* **User Reviews and Ratings:** Build trust and transparency in the platform.
* **Offline Support:** Basic functionality when network connectivity is limited.
* **Multi-language Support.**

## 🤝 Contributing

Contributions are welcome! If you'd like to contribute, please follow these steps:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/your-feature-name`).
3.  Make your changes.
4.  Commit your changes (`git commit -m 'Add some feature'`).
5.  Push to the branch (`git push origin feature/your-feature-name`).
6.  Open a Pull Request.

Please make sure to update tests as appropriate.

## 📄 License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file. Please refer to the `LICENSE` file in the root of the repository for full details.

---

Thank you for checking out AgriCycle! We hope this platform contributes to a more sustainable agricultural ecosystem.
