import threading
import time
from concurrent.futures import ThreadPoolExecutor, Future
from typing import Any, Dict
from icecream import ic

from storage.renderable import Renderable

class RenderQueue:

    def __init__(self):
        self.executor: ThreadPoolExecutor = ThreadPoolExecutor()
        self.tasks: Dict[int, Future] = {}
        self.lock: threading.RLock = threading.RLock()  # reentrant lock

    def start_render(self, renderable: Renderable) -> Future | None:
        taskid: int = hash(renderable)
        with self.lock:
            # If task already exists, do not start a new one
            if taskid in self.tasks and not self.tasks[taskid].done():
                return None
            # Start a new task and store its Future object
            task = self.executor.submit(renderable.render)
            self.tasks[taskid] = task
            return task

    # Get the task from the map by renderable
    def _task(self, renderable: Renderable) -> Future:
        with self.lock:
            task = self.tasks.get(hash(renderable))
            return task

    def get_status(self, renderable: Renderable) -> str:
        with self.lock:
            task = self._task(renderable)
            if task is None:
                return "No task found"
            elif task.running():
                return "Rendering in progress"
            elif task.done():
                return "Rendering complete"
            else:
                return "Task pending"

    def wait_for_completion(self, renderable: Renderable) -> Any:
        print(f"Render queue: waiting for completion: {renderable}", flush=True)
        with self.lock:
            task = self._task(renderable)
            print(f"Task: {task}", flush=True)
            if task is None:
                raise Exception(f"Task not found: {hash(renderable)}, {renderable}")
            try:
                result = task.result()  # This will block until the task is complete
            except Exception as e:
                print(f"Error in task: {task}, {e}", flush=True)
                # show the stack trace
                import traceback
                trace = traceback.format_exc()
                print(f"Traceback: {trace}", flush=True)
                # raise e
        print(f"Task completed: {renderable}", flush=True)
        return result


# main
if __name__ == '__main__':

    class TestRenderable(Renderable):
        def render(self):
            print("Rendering...")
            try:
                # Simulate work
                time.sleep(3)
            except Exception as e:
                print(f"Error during rendering: {e}")
            print("Render Complete!")

        def __hash__(self):
            return hash("TestRenderable")


    def main():
        # Example usage:
        queue = RenderQueue()
        renderable = TestRenderable()
        task = queue.start_render(renderable)
        ic(task)
        status = queue.get_status(renderable)
        ic(status)
        result = queue.wait_for_completion(renderable)
        ic(result)
        ...

    main()
