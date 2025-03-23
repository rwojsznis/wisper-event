# Example

class MySuccessEvent
  attr_reader :message

  def initialize(message:)
    @message = message
  end
end

class MyFailureEvent
  attr_reader :message

  def initialize(message)
    @message = message
  end
end

class MyCommand
  include Wisper::Publisher

  def execute(be_successful)
    if be_successful
      broadcast('success', message: 'hello')
      broadcast(MySuccessEvent.new(message: 'hello'))
    else
      broadcast('failure', 'world')
      broadcast(MyFailureEvent.new('world'))
    end
  end
end

class ClassicListener
  def success(message:) end
end

class StructuredListener
  include Wisper::Listener

  def initialize(verify)
    @verify = verify
  end

  on(MySuccessEvent) do |event|
    @verify.call_success(event.message)
  end

  on(MyFailureEvent) do |event|
    @verify.call_failure(event.message)
  end
end

describe Wisper do

  it 'subscribes object to all published events' do
    classic_listener = instance_double(ClassicListener)
    expect(classic_listener).to receive(:success).with(message: 'hello')

    command = MyCommand.new
    command.subscribe(classic_listener)

    command.execute(true)
  end

  it 'handles structured events correctly' do
    verify = double('verify')
    expect(verify).to receive(:call_success).with('hello')
    expect(verify).to receive(:call_failure).with('world')

    command = MyCommand.new
    command.subscribe(StructuredListener.new(verify))

    command.execute(true)
    command.execute(false)
  end

  it 'subscribed classic and structured listener to specific event' do
    classic_listener = instance_double(ClassicListener)
    expect(classic_listener).to receive(:success).with(message: 'hello')

    command = MyCommand.new
    command.subscribe(classic_listener)

    verify = double('verify')
    expect(verify).to receive(:call_success).with('hello')
    command.subscribe(StructuredListener.new(verify))

    command.execute(true)
  end

  it 'maps events to different methods' do
    listener_1 = double('listener')
    listener_2 = double('listener')
    expect(listener_1).to receive(:happy_days).with(message: 'hello')
    expect(listener_2).to receive(:sad_days).with('world', **{})

    command = MyCommand.new

    command.subscribe(listener_1, :on => :success, :with => :happy_days)
    command.subscribe(listener_2, :on => :failure, :with => :sad_days)

    command.execute(true)
    command.execute(false)
  end

  it 'subscribes block to all published events' do
    insider = double('Insider')

    expect(insider).to receive(:render).with('hello')

    command = MyCommand.new
    command.on(MySuccessEvent) { |event| insider.render(event.message) }

    command.execute(true)
  end

  it 'subscribes block can be chained' do
    insider = double('Insider')

    expect(insider).to receive(:render).with('success')
    expect(insider).to receive(:render).with('failure')

    command = MyCommand.new

    command.on(:success) { |message| insider.render('success') }
      .on(:failure) { |message| insider.render('failure') }

    command.execute(true)
    command.execute(false)
  end
end
