module Custom::AsyncDispatcher
  def listeners
    super + [Custom::CrmListener.instance]
  end
end
