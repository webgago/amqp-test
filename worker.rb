require "amqp"

require "amqp/extensions/rabbitmq"

EventMachine.run do
  connection = AMQP.connect(:host => '127.0.0.1')
  puts "Connecting to AMQP broker. Running #{AMQP::VERSION} version of the gem..."


  AMQP::Channel.new(connection) do |channel|
    puts "Channel #{channel.id} is now open"
    channel.prefetch(1)
    channel.confirm_select
    channel.on_error do |_, channel_close|
      puts "Oops! a channel-level exception: #{channel_close.reply_text}"
    end
    channel.on_ack do |basic_ack|
      puts "Received basic_ack: multiple = #{basic_ack.multiple}, delivery_tag = #{basic_ack.delivery_tag}"
    end

    channel.queue("soap", :durable => true, :auto_delete => false).subscribe(:ack => true) do |metadata, payload|
      puts "Received #{payload}"
      metadata.ack
    end

  end

  show_stopper = Proc.new {
    connection.close { EventMachine.stop }
  }

  Signal.trap('INT', show_stopper)
  Signal.trap('TERM', show_stopper)
end