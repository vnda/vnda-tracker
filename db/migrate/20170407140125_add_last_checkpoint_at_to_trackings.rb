class AddLastCheckpointAtToTrackings < ActiveRecord::Migration[5.0]
  def change
    add_column :trackings, :last_checkpoint_at, :datetime
  end
end
