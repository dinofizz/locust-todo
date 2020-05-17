import lorem
from locust import HttpUser, task, between, SequentialTaskSet


class TodoUser(HttpUser):
    wait_time = between(2, 5)
    todo_item = None

    @task
    class CrudSequence(SequentialTaskSet):
        @task
        def create_todo(self):
            headers = {"content-type": "application/json"}
            response = self.client.post(
                "/todo",
                json={"Description": lorem.sentence(), "Completed": False},
                headers=headers,
            )
            self.user.todo_item = response.json()

        @task
        def retrieve_todo(self):
            self.client.get(f"/todo/{self.user.todo_item['Id']}", name="/todo/[id]")

        @task
        def update_todo(self):
            headers = {"content-type": "application/json"}
            self.user.todo_item["Completed"] = True
            self.client.put(
                f"/todo/{self.user.todo_item['Id']}",
                json=self.user.todo_item,
                headers=headers,
                name="/todo/[id]"
            )

        @task
        def delete_todo(self):
            self.client.delete(f"/todo/{self.user.todo_item['Id']}", name="/todo/[id]")
