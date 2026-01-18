# NEXT: Nurturing Entrepreneurs and eXeptional Talent

[![Web App](https://img.shields.io/badge/Web-App-blue?style=for-the-badge)](https://next-app-lake-nu.vercel.app/)
[![Flutter](https://img.shields.io/badge/Built_with-Flutter-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev/)

**NEXT** is a premier B2B platform designed exclusively to bridge the gap between **Established Companies** and **High-Potential Startups**. We facilitate meaningful partnerships, investment opportunities, and strategic collaborations.

> **Note:** This platform focuses strictly on business-to-business (B2B) interactions. Individual job seeker features have been streamlined out to focus on organizational growth.

---

## 🌟 Key Features

### 🏢 For Established Companies
*   **Startup Discovery**: Browse and filter a curated list of startups by sector (Fintech, AI, Healthtech, etc.).
*   **Investment & Funding**: View funding goals and support startups directly via integrated payment gateways.
*   **Pairing & Analytics**: Connect with startups using secure pairing codes and monitor their growth KPIs (Monthly/Yearly metrics).
*   **Direct Communication**: Real-time messaging with startup founders.
*   **Portfolio Management**: Track invested companies and their activity timelines.

### 🚀 For Startups
*   **Visibility**: Create comprehensive profiles showcasing your mission, tech stack, and funding stage.
*   **Funding Opportunities**: Display funding requirements and accept support from established industry players.
*   **Networking**: Connect directly with industry leaders and potential acquirers/investors.
*   **Meeting Scheduler**: Organize pitch meetings and collaboration discussions.
*   **Resource Access**: Tools and insights to accelerate growth.

---

## 🛠️ Technology Stack

*   **Frontend**: [Flutter](https://flutter.dev/) (Web, Android, iOS)
*   **Backend**: PHP (RESTful API)
*   **Database**: MySQL
*   **Realtime/Storage**: [Supabase](https://supabase.com/) & Integrated PHP APIs
*   **Payments**: Razorpay / UPI Integration
*   **State Management**: `setState` & `Provider` patterns
*   **Local Storage**: `flutter_secure_storage` & `shared_preferences`

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (Version 3.7.2 or higher)
*   [Git](https://git-scm.com/)
*   A browser (Chrome/Edge) for web debugging or an Android Emulator/Device.
*   **Active Internet Connection** (Required for API and Supabase connectivity)

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/Vyshak10/Next_app.git
    cd Next_app
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the Application**
    *   **For Web:**
        ```bash
        flutter run -d chrome
        ```
    *   **For Windows:**
        ```bash
        flutter run -d windows
        ```
    *   **For Android:**
        ```bash
        flutter run
        ```

### Configuration
The app is pre-configured to connect to the backend.
*   **Backend URL**: Defined in `lib/config.dart`.
*   **Supabase/API Keys**: Managed internally.

---

## 📂 Project Structure

```
lib/
├── common_widget/       # Reusable UI components (Buttons, Cards, Chat)
├── routes/              # Application routing (app_routes.dart)
├── services/            # API handling and Authentication (auth_service.dart, api_service.dart)
├── view/                # Main Application Screens
│   ├── analytics/       # Graphs and Data Visualization
│   ├── chat/            # Chat implementation
│   ├── homepage/        # Company & Startup Dashboards
│   ├── login/           # Authentication Screens (Login, Signup)
│   ├── meetings/        # Meeting Scheduling & Notifications
│   ├── posts/           # Feed and Post Creation
│   └── profile/         # User Profile Management
└── main.dart            # Entry point
```

---

## 🤝 Contributing

1.  Fork the project
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.
