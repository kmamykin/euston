class Cranky::Factory
  def commit
    c = define  class: Hash,
                id: Uuid.generate,
                message_source_id: Factory.build(:message_source_id),
                sequence: 1,
                origin: Factory.build(:book_tee_command).to_hash

    c[:events] = options[:events] || [
      Factory.build(:tee_booked_event,
        course_id:  c[:origin][:body][:course_id],
        player_id:  c[:origin][:body][:player_id],
        time:       c[:origin][:body][:time]
      ).to_hash ]

    c[:commands] = options[:commands] || [
      Factory.build(:check_for_slow_play_command,
        course_id:  c[:origin][:body][:course_id],
        player_id:  c[:origin][:body][:player_id],
        time:       c[:origin][:body][:time]
      ).to_hash
    ]

    Euston::Commit.new c
  end
end
