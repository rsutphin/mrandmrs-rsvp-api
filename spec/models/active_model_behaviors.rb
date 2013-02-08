shared_examples 'an ActiveModel instance in this project' do
  describe '#to_model' do
    it 'is self' do
      record.to_model.should be(record)
    end
  end

  describe '#to_param' do
    it 'is the ID' do
      record.to_param.should == record.id
    end
  end

  describe '#to_key' do
    it 'is an array containing only the ID' do
      record.to_key.should == [record.id]
    end
  end

  describe '#to_partial_path' do
    it 'behavior' do
      pending 'Do not care about this'
    end
  end

  describe '#persisted?' do
    it 'is always true' do
      record.should be_persisted
    end
  end

  describe '.model_name' do
    it 'returns a name based on the class name' do
      record.class.model_name.singular.should == record.class.name.downcase
    end
  end
end
