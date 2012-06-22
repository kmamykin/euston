class Cranky::Factory
  def message_source_id
    Euston::MessageSourceId.new Uuid.generate, Faker::Lorem.word
  end
end
