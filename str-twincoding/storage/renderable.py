
class Renderable:

    def render(self):
        raise NotImplementedError("Subclasses must implement the render method.")

    # hashable
    def __hash__(self):
        raise NotImplementedError("Subclasses must implement the __hash__ method.")
