class Cranky::Factory
  def snapshot
    s = define  class: Hash,
                event_source_id: Uuid.generate,
                sequence: 1,
                type: Faker::Lorem.word,
                version: 1,
                idempotence_message_ids: Array.new(rand(10) + 1) { Uuid.generate },
                body: Hash[Array.new(rand(4) + 1) {
                  "#{Faker::Lorem.word}#{Uuid.generate.gsub /-/, ''}"
                }.map { |key| [key, rand(100)] }]

    Euston::Snapshot.new s
  end
end
