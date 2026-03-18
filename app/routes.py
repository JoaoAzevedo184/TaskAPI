from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import select
from sqlmodel import Session
from .models import Task
from .db import get_session

router = APIRouter()


@router.post("/tasks", response_model=Task, status_code=201)
def create_task(task: Task, session: Session = Depends(get_session)):
    session.add(task)
    session.commit()
    session.refresh(task)
    return task


@router.get("/tasks")
def list_tasks(session: Session = Depends(get_session)):
    tasks = session.exec(select(Task)).all()
    return tasks


@router.get("/tasks/{task_id}")
def get_task(task_id: int, session: Session = Depends(get_session)):
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@router.put("/tasks/{task_id}")
def update_task(
    task_id: int, updated: Task, session: Session = Depends(get_session)
):
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    task.title = updated.title
    task.description = updated.description
    task.done = updated.done
    session.add(task)
    session.commit()
    session.refresh(task)
    return task


@router.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: int, session: Session = Depends(get_session)):
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    session.delete(task)
    session.commit()
