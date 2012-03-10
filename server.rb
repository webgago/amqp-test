require "bundler"
require "sinatra"
require "amqp"

Bundler.setup

require 'amqp'
require 'amqp/utilities/event_loop_helper'

puts "EventMachine.reactor_running? => #{EventMachine.reactor_running?.inspect}"

AMQP::Utilities::EventLoopHelper.run do
  AMQP.start

  exchange = AMQP.channel.fanout("amq.fanout")

  q = AMQP.channel.queue("soap", :durable => true, :auto_delete => false)
  q.bind(exchange)
  exchange.publish("Started!", :routing_key => q.name)
end

get '/' do
  e = AMQP.channel.fanout("amq.fanout")
  q = AMQP.channel.queue("soap", :durable => true, :auto_delete => false)
  q.bind(e)

  e.publish("#{params[:msg]} at (#{Time.now.to_i})", :persistent => true, :routing_key => q.name)
  erb :index
end

__END__


@@ layout
<html>
  <head>
    <title>Sinatra + Sidekiq</title>
    <body>
      <%= yield %>
    </body>
</html>

@@ index
  <h1>Sinata + Sidekiq Example</h1>
  <h2>Failed: <%= @failed %></h2>
  <h2>Processed: <%= @processed %></h2>

  <form method="get" action="/">
    <input type="text" name="msg">
    <input type="submit" value="Add Message">
  </form>

  <a href="/">Refresh page</a>

