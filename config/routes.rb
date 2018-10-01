Spree::Core::Engine.add_routes do
  post '/spree_coinbase/notify', to: "coinbase_commerce#notify"
end
