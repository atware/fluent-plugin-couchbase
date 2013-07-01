# vim: fileencoding=utf-8 ts=2 sts=2 sw=2 et si ai :
module Helpers

  def generate_document_key(min=1, max=999)
    "spec_pk_#{Random.rand(min..max)}"
  end

  def write(driver)
    time1 = Time.mktime(2013, 6, 1, 11, 22, 33)
    time2 = Time.mktime(2013, 6, 1, 11, 22, 35)

    record1 = {'a' => 10, 'b' => 'Tesla'}
    record2 = {'a' => 20, 'b' => 'Edison'}

    record1_for_id = {'a' => 10, 'b' => 'Tesla', 'tag' => 'test', 'time' => time1.to_i, :ttl => 10}
    record2_for_id = {'a' => 20, 'b' => 'Edison', 'tag' => 'test', 'time' => time2.to_i, :ttl => 10}


    id1 = Digest::MD5.hexdigest(record1_for_id.to_s)
    id2 = Digest::MD5.hexdigest(record2_for_id.to_s)

    # store both records in an array to aid with verification
    test_records = [record1, record2]
    test_times = [time1, time2]

    test_records.each_with_index do |rec, idx|
      Time.stub!(:now).and_return(test_times[idx])
      driver.emit(rec)
    end
    driver.run # persists to couchbase

    # query couchbase to verify data was correctly persisted
    db_records = driver.instance.connection.get(id1, id2)

    db_records.count.should eq(test_records.count)
    db_records.each_with_index do |db_record, idx| # records should be sorted by row_key asc
      test_record = test_records[idx]
      db_record['tag'].should eq(test_record['tag'])
      db_record['time'].should eq(test_record['time'])
      db_record['a'].should eq(test_record['a'])
      db_record['b'].should eq(test_record['b'])
      if driver.instance.include_ttl
        db_record['ttl'].should_not be_nil
      else
        db_record['ttl'].should be_nil
      end
    end

  end # def write

end # module Helpers
