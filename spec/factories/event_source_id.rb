class Cranky::Factory
  def event_source_id
    Euston::EventSourceId.new Uuid.generate, Faker::Lorem.word
  end
end
