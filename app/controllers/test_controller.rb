class TestController
  def index
    redirect_to params.merge(action: :elsewhere)
  end
end
