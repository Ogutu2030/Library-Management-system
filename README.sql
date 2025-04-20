# File structure:
# - main.py (FastAPI application)
# - database.py (Database connections and setup)
# - models.py (Pydantic models for validation)
# - requirements.txt (Dependencies)
# - .env.example (Example environment variables)

##########################
# File: database.py
##########################

import mysql.connector
from mysql.connector import Error
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database configuration 
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
DB_NAME = os.getenv("DB_NAME", "task_management")

def create_connection():
    """Create a database connection to MySQL server"""
    connection = None
    try:
        connection = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            passwd=DB_PASSWORD,
            database=DB_NAME
        )
        print("Connection to MySQL DB successful")
    except Error as e:
        print(f"The error '{e}' occurred")
    
    return connection

def execute_query(connection, query, params=None):
    """Execute a query with optional parameters"""
    cursor = connection.cursor(dictionary=True)
    try:
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)
        connection.commit()
        return cursor
    except Error as e:
        print(f"The error '{e}' occurred")
        return None

def initialize_database():
    """Create database and tables if they don't exist"""
    try:
        # First connect without specifying a database to create it if needed
        conn = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            passwd=DB_PASSWORD
        )
        
        # Create database if it doesn't exist
        cursor = conn.cursor()
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME}")
        cursor.close()
        conn.close()
        
        # Now connect to the database
        connection = create_connection()
        
        # Create users table
        create_users_table = """
        CREATE TABLE IF NOT EXISTS users (
            user_id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) NOT NULL UNIQUE,
            email VARCHAR(100) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            first_name VARCHAR(50),
            last_name VARCHAR(50),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            role ENUM('admin', 'user') DEFAULT 'user'
        );
        """
        
        # Create projects table
        create_projects_table = """
        CREATE TABLE IF NOT EXISTS projects (
            project_id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            description TEXT,
            owner_id INT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            deadline DATE,
            status ENUM('active', 'completed', 'on_hold', 'cancelled') DEFAULT 'active',
            FOREIGN KEY (owner_id) REFERENCES users(user_id) ON DELETE CASCADE
        );
        """
        
        # Create tasks table
        create_tasks_table = """
        CREATE TABLE IF NOT EXISTS tasks (
            task_id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(100) NOT NULL,
            description TEXT,
            project_id INT,
            assigned_to INT,
            created_by INT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            due_date DATE,
            priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
            status ENUM('todo', 'in_progress', 'review', 'done') DEFAULT 'todo',
            FOREIGN KEY (project_id) REFERENCES projects(project_id) ON DELETE SET NULL,
            FOREIGN KEY (assigned_to) REFERENCES users(user_id) ON DELETE SET NULL,
            FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE CASCADE
        );
        """
        
        # Execute table creation queries
        execute_query(connection, create_users_table)
        execute_query(connection, create_projects_table)
        execute_query(connection, create_tasks_table)
        
        # Insert sample data if tables are empty
        cursor = connection.cursor()
        cursor.execute("SELECT COUNT(*) FROM users")
        user_count = cursor.fetchone()[0]
        
        if user_count == 0:
            insert_sample_data(connection)
        
        cursor.close()
        connection.close()
        print("Database initialized successfully")
        
    except Error as e:
        print(f"Error initializing database: {e}")

def insert_sample_data(connection):
    """Insert sample data into the database"""
    
    # Insert sample users
    sample_users = """
    INSERT INTO users (username, email, password_hash, first_name, last_name, role)
    VALUES
        ('admin', 'admin@example.com', '$2b$12$BPgM6HQNbJnCQwSG8dO4e.LV4TCMwRoD1Wt7xm7LvGj8fHIHGrR1.', 'Admin', 'User', 'admin'),
        ('john_doe', 'john@example.com', '$2b$12$BPgM6HQNbJnCQwSG8dO4e.LV4TCMwRoD1Wt7xm7LvGj8fHIHGrR1.', 'John', 'Doe', 'user'),
        ('jane_smith', 'jane@example.com', '$2b$12$BPgM6HQNbJnCQwSG8dO4e.LV4TCMwRoD1Wt7xm7LvGj8fHIHGrR1.', 'Jane', 'Smith', 'user');
    """
    
    # Insert sample projects
    sample_projects = """
    INSERT INTO projects (name, description, owner_id, deadline, status)
    VALUES
        ('Website Redesign', 'Update the company website with modern design', 1, DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY), 'active'),
        ('Mobile App Development', 'Create a new mobile application for customers', 2, DATE_ADD(CURRENT_DATE, INTERVAL 60 DAY), 'active'),
        ('Database Migration', 'Migrate legacy database to new system', 1, DATE_ADD(CURRENT_DATE, INTERVAL 15 DAY), 'on_hold');
    """
    
    # Insert sample tasks
    sample_tasks = """
    INSERT INTO tasks (title, description, project_id, assigned_to, created_by, due_date, priority, status)
    VALUES
        ('Design Homepage', 'Create mockups for the new homepage', 1, 3, 1, DATE_ADD(CURRENT_DATE, INTERVAL 7 DAY), 'high', 'in_progress'),
        ('Backend API', 'Develop REST API endpoints', 1, 2, 1, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY), 'high', 'todo'),
        ('User Authentication', 'Implement login and registration', 2, 2, 2, DATE_ADD(CURRENT_DATE, INTERVAL 10 DAY), 'urgent', 'in_progress'),
        ('Database Schema Design', 'Design new database schema', 3, 1, 1, DATE_ADD(CURRENT_DATE, INTERVAL 5 DAY), 'medium', 'review'),
        ('Data Export Script', 'Write script to export old data', 3, 2, 1, DATE_ADD(CURRENT_DATE, INTERVAL 8 DAY), 'medium', 'todo');
    """
    
    execute_query(connection, sample_users)
    execute_query(connection, sample_projects)
    execute_query(connection, sample_tasks)
    print("Sample data inserted successfully")

##########################
# File: models.py
##########################

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date, datetime

# User models
class UserBase(BaseModel):
    username: str
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    role: str = "user"

class UserCreate(UserBase):
    password: str

class User(UserBase):
    user_id: int
    created_at: datetime

    class Config:
        orm_mode = True

# Project models
class ProjectBase(BaseModel):
    name: str
    description: Optional[str] = None
    owner_id: int
    deadline: Optional[date] = None
    status: str = "active"

class ProjectCreate(ProjectBase):
    pass

class Project(ProjectBase):
    project_id: int
    created_at: datetime

    class Config:
        orm_mode = True

# Task models
class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    project_id: Optional[int] = None
    assigned_to: Optional[int] = None
    created_by: int
    due_date: Optional[date] = None
    priority: str = "medium"
    status: str = "todo"

class TaskCreate(TaskBase):
    pass

class Task(TaskBase):
    task_id: int
    created_at: datetime

    class Config:
        orm_mode = True

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    project_id: Optional[int] = None
    assigned_to: Optional[int] = None
    due_date: Optional[date] = None
    priority: Optional[str] = None
    status: Optional[str] = None

##########################
# File: main.py
##########################

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from typing import List
import database
from models import User, UserCreate, UserBase, Project, ProjectCreate, ProjectBase, Task, TaskCreate, TaskBase, TaskUpdate

# Initialize the database
database.initialize_database()

# Create FastAPI app
app = FastAPI(
    title="Task Management API",
    description="CRUD API for task management with MySQL backend",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency to get database connection
def get_db():
    connection = database.create_connection()
    try:
        yield connection
    finally:
        connection.close()

# Root endpoint
@app.get("/")
def read_root():
    return {"message": "Welcome to the Task Management API"}

#########################
# User CRUD Operations
#########################

@app.post("/users/", response_model=User, status_code=status.HTTP_201_CREATED)
def create_user(user: UserCreate, db = Depends(get_db)):
    # In production, hash the password securely
    query = """
    INSERT INTO users (username, email, password_hash, first_name, last_name, role)
    VALUES (%s, %s, %s, %s, %s, %s)
    """
    params = (user.username, user.email, user.password, user.first_name, user.last_name, user.role)
    
    cursor = database.execute_query(db, query, params)
    if not cursor:
        raise HTTPException(status_code=400, detail="Could not create user")
    
    user_id = cursor.lastrowid
    
    # Get the created user
    query = "SELECT * FROM users WHERE user_id = %s"
    cursor = database.execute_query(db, query, (user_id,))
    new_user = cursor.fetchone()
    
    return new_user

@app.get("/users/", response_model=List[User])
def get_users(db = Depends(get_db)):
    query = "SELECT * FROM users"
    cursor = database.execute_query(db, query)
    users = cursor.fetchall()
    return users

@app.get("/users/{user_id}", response_model=User)
def get_user(user_id: int, db = Depends(get_db)):
    query = "SELECT * FROM users WHERE user_id = %s"
    cursor = database.execute_query(db, query, (user_id,))
    user = cursor.fetchone()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.put("/users/{user_id}", response_model=User)
def update_user(user_id: int, user: UserBase, db = Depends(get_db)):
    # Check if user exists
    check_query = "SELECT * FROM users WHERE user_id = %s"
    check_cursor = database.execute_query(db, check_query, (user_id,))
    existing_user = check_cursor.fetchone()
    
    if not existing_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Update user
    query = """
    UPDATE users 
    SET username = %s, email = %s, first_name = %s, last_name = %s, role = %s
    WHERE user_id = %s
    """
    params = (user.username, user.email, user.first_name, user.last_name, user.role, user_id)
    database.execute_query(db, query, params)
    
    # Get updated user
    updated_cursor = database.execute_query(db, check_query, (user_id,))
    updated_user = updated_cursor.fetchone()
    return updated_user

@app.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(user_id: int, db = Depends(get_db)):
    # Check if user exists
    check_query = "SELECT * FROM users WHERE user_id = %s"
    check_cursor = database.execute_query(db, check_query, (user_id,))
    user = check_cursor.fetchone()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Delete user
    query = "DELETE FROM users WHERE user_id = %s"
    database.execute_query(db, query, (user_id,))
    
    return None

#########################
# Project CRUD Operations
#########################

@app.post("/projects/", response_model=Project, status_code=status.HTTP_201_CREATED)
def create_project(project: ProjectCreate, db = Depends(get_db)):
    # Verify owner exists
    check_query = "SELECT * FROM users WHERE user_id = %s"
    check_cursor = database.execute_query(db, check_query, (project.owner_id,))
    user = check_cursor.fetchone()
    
    if not user:
        raise HTTPException(status_code=404, detail="Owner not found")
    
    # Create project
    query = """
    INSERT INTO projects (name, description, owner_id, deadline, status)
    VALUES (%s, %s, %s, %s, %s)
    """
    params = (project.name, project.description, project.owner_id, project.deadline, project.status)
    
    cursor = database.execute_query(db, query, params)
    if not cursor:
        raise HTTPException(status_code=400, detail="Could not create project")
    
    project_id = cursor.lastrowid
    
    # Get the created project
    query = "SELECT * FROM projects WHERE project_id = %s"
    cursor = database.execute_query(db, query, (project_id,))
    new_project = cursor.fetchone()
    
    return new_project

@app.get("/projects/", response_model=List[Project])
def get_projects(db = Depends(get_db)):
    query = "SELECT * FROM projects"
    cursor = database.execute_query(db, query)
    projects = cursor.fetchall()
    return projects

@app.get("/projects/{project_id}", response_model=Project)
def get_project(project_id: int, db = Depends(get_db)):
    query = "SELECT * FROM projects WHERE project_id = %s"
    cursor = database.execute_query(db, query, (project_id,))
    project = cursor.fetchone()
    
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    return project

@app.put("/projects/{project_id}", response_model=Project)
def update_project(project_id: int, project: ProjectBase, db = Depends(get_db)):
    # Check if project exists
    check_query = "SELECT * FROM projects WHERE project_id = %s"
    check_cursor = database.execute_query(db, check_query, (project_id,))
    existing_project = check_cursor.fetchone()
    
    if not existing_project:
        raise HTTPException(status_code=404, detail="Project not found")
    
    # Update project
    query = """
    UPDATE projects 
    SET name = %s, description = %s, owner_id = %s, deadline = %s, status = %s
    WHERE project_id = %s
    """
    params = (project.name, project.description, project.owner_id, project.deadline, project.status, project_id)
    database.execute_query(db, query, params)
    
    # Get updated project
    updated_cursor = database.execute_query(db, check_query, (project_id,))
    updated_project = updated_cursor.fetchone()
    return updated_project

@app.delete("/projects/{project_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_project(project_id: int, db = Depends(get_db)):
    # Check if project exists
    check_query = "SELECT * FROM projects WHERE project_id = %s"
    check_cursor = database.execute_query(db, check_query, (project_id,))
    project = check_cursor.fetchone()
    
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    
    # Delete project
    query = "DELETE FROM projects WHERE project_id = %s"
    database.execute_query(db, query, (project_id,))
    
    return None

#########################
# Task CRUD Operations
#########################

@app.post("/tasks/", response_model=Task, status_code=status.HTTP_201_CREATED)
def create_task(task: TaskCreate, db = Depends(get_db)):
    # Create task
    query = """
    INSERT INTO tasks (title, description, project_id, assigned_to, created_by, due_date, priority, status)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """
    params = (task.title, task.description, task.project_id, task.assigned_to, 
              task.created_by, task.due_date, task.priority, task.status)
    
    cursor = database.execute_query(db, query, params)
    if not cursor:
        raise HTTPException(status_code=400, detail="Could not create task")
    
    task_id = cursor.lastrowid
    
    # Get the created task
    query = "SELECT * FROM tasks WHERE task_id = %s"
    cursor = database.execute_query(db, query, (task_id,))
    new_task = cursor.fetchone()
    
    return new_task

@app.get("/tasks/", response_model=List[Task])
def get_tasks(project_id: Optional[int] = None, db = Depends(get_db)):
    if project_id:
        query = "SELECT * FROM tasks WHERE project_id = %s"
        cursor = database.execute_query(db, query, (project_id,))
    else:
        query = "SELECT * FROM tasks"
        cursor = database.execute_query(db, query)
    
    tasks = cursor.fetchall()
    return tasks

@app.get("/tasks/{task_id}", response_model=Task)
def get_task(task_id: int, db = Depends(get_db)):
    query = "SELECT * FROM tasks WHERE task_id = %s"
    cursor = database.execute_query(db, query, (task_id,))
    task = cursor.fetchone()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task

@app.put("/tasks/{task_id}", response_model=Task)
def update_task(task_id: int, task: TaskUpdate, db = Depends(get_db)):
    # Check if task exists
    check_query = "SELECT * FROM tasks WHERE task_id = %s"
    check_cursor = database.execute_query(db, check_query, (task_id,))
    existing_task = check_cursor.fetchone()
    
    if not existing_task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Build dynamic update query based on provided fields
    update_fields = []
    params = []
    
    if task.title is not None:
        update_fields.append("title = %s")
        params.append(task.title)
    
    if task.description is not None:
        update_fields.append("description = %s")
        params.append(task.description)
    
    if task.project_id is not None:
        update_fields.append("project_id = %s")
        params.append(task.project_id)
    
    if task.assigned_to is not None:
        update_fields.append("assigned_to = %s")
        params.append(task.assigned_to)
    
    if task.due_date is not None:
        update_fields.append("due_date = %s")
        params.append(task.due_date)
    
    if task.priority is not None:
        update_fields.append("priority = %s")
        params.append(task.priority)
    
    if task.status is not None:
        update_fields.append("status = %s")
        params.append(task.status)
    
    if not update_fields:
        return existing_task
    
    # Add task_id to params
    params.append(task_id)
    
    # Construct and execute update query
    query = f"UPDATE tasks SET {', '.join(update_fields)} WHERE task_id = %s"
    database.execute_query(db, query, tuple(params))
    
    # Get updated task
    updated_cursor = database.execute_query(db, check_query, (task_id,))
    updated_task = updated_cursor.fetchone()
    return updated_task

@app.delete("/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(task_id: int, db = Depends(get_db)):
    # Check if task exists
    check_query = "SELECT * FROM tasks WHERE task_id = %s"
    check_cursor = database.execute_query(db, check_query, (task_id,))
    task = check_cursor.fetchone()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Delete task
    query = "DELETE FROM tasks WHERE task_id = %s"
    database.execute_query(db, query, (task_id,))
    
    return None

##########################
# File: requirements.txt
##########################
# fastapi==0.95.1
# uvicorn==0.22.0
# python-dotenv==1.0.0
# mysql-connector-python==8.0.33
# pydantic==1.10.7

##########################
# File: .env.example
##########################
# DB_HOST=localhost
# DB_USER=root
# DB_PASSWORD=password
# DB_NAME=task_management
