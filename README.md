# VR-application For Content Playback

<br>The main set of scripts is located in Client/Assets/Scripts/: 

* **DeviceInfo.cs** – _stores information about the device (ID, name, status, etc.)._ 
* **DeviceManager.cs** – _manages the current device and its parameters._ _
* **HudController.cs** – _controls the HUD (Heads-Up Display) interface in the VR application._ 
* **NetworkController.cs** – _establishes and maintains a WebSocket connection with the server; handles network interaction with other applications._ 
* **NetworkScanner.cs** – _scans the local network to find the server before connecting._ 
* **PlaybackStatus.cs** – _stores and updates the playback status of the video._ 
* **VideoDownloader.cs** – _downloads video files from the server to the device and manages the content in local storage._ 
* **VideoPlayerController.cs** – _controls the playback of 360-degree videos in Unity._ 

<br>And in Client/Assets/Shaders/
* **360Video.shader** – _ensures correct rendering of 360-degree video on a sphere in Unity._ 

# Content Playback Control Center

<br>The main set of files is located in Server/server/lib/ 

* **client_info.dart** – _data structure describing a client (ID, name, status, IP, etc.)_ _
* **client_list_item.dart** – _widget representing a single client in the list; displays its name, status, and control buttons._ 
* **client_list.dart** – _widget displaying the list of all connected clients; handles list updates and display logic._ 
* **main.dart** – _entry point of the application; initializes the UI, application state, and networking services._ 
* **name_mapping_service.dart** – _saves and loads the mapping between client IDs and user-defined names._ 
* **networking.dart** – _manages the WebSocket connection with clients; sends commands and receives status updates._ 
* **selection_manager.dart** – _handles logic for selecting one or multiple clients for control (e.g. video playback)._ 
* **video_control_panel.dart** – _video control panel (play, pause, file selection, etc.)._ 
* **video_repository.dart** – _storage and handler for the list of available video files fetched from the server._ 

# Content Management Web-Service

The main set of files is located in WebUpdater/

* **__init__.py** – _makes the folder a Python module; may contain package initialization (usually empty)._ 
* **dbconnection.py** – _establishes a connection to the database (e.g., using SQLAlchemy)._ 
* **dbcontroller.py** – _contains functions for interacting with the database: adding, deleting, retrieving data, etc._ 
* **dbmodels.py** – _defines the database tables using SQLAlchemy models._ 
* **dbschemas.py** – _defines Pydantic schemas for data validation and serialization when working with the API._ 
* **main.py** – _entry point of the FastAPI application; initializes the API, routes, and dependencies._ 
* **requirements.txt** – _list of project dependencies (libraries required for running the application)._ 
