class AddProxiesTable < ActiveRecord::Migration
  def self.up
    create_table :proxies do |t|
      t.string :to
    end
  end

  def self.down
    drop_table :proxies
  end
end