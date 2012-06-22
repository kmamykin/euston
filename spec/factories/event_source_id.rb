class Cranky::Factory
  def event_source_id
    Euston::MessageSourceId.new Uuid.generate, Faker::Lorem.word
  end
end
