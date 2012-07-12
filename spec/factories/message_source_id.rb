class Cranky::Factory
  def message_source_id
    Euston::MessageSourceId.new Uuid.generate, Scenarios::GolfCourse::Starter
  end
end
