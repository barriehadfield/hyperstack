require 'spec_helper'

# Just checks to make sure all methods are available when either subclassing or including

describe Hyperstack::State::Observable do
  class Store
    include Hyperstack::State::Observable
  end
  let(:store) { Store.new }

  context 'observe instance method' do
    it "can be passed a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(store)
      store.instance_eval { @var = 12 }
      expect(store.instance_eval { observe { @var } }).to eq(12)
    end
    it "can be used without a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(store)
      store.instance_eval { observe }
    end
  end

  context 'mutate instance method' do
    it "can be passed a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store)
      expect(store.instance_eval { mutate { @var = 12 } }).to eq(12)
    end
    it "can be used without a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store)
      store.instance_eval { mutate }
    end
  end

  context 'observe class method' do
    it "can be passed a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(Store)
      Store.instance_eval { @var = 12 }
      expect(Store.instance_eval { observe { @var } }).to eq(12)
    end
    it "can be used without a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(Store)
      Store.instance_eval { observe }
    end
  end

  context 'mutate class method' do
    it "can be passed a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(Store)
      expect(Store.instance_eval { mutate { @var = 12 } }).to eq(12)
    end
    it "can be used without a block" do
      expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(Store)
      Store.instance_eval { mutate }
    end
  end

  it 'observer instance method definition' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(store)
    Store.observer(:read_state) { @state }
    store.instance_eval { @state = 123 }
    expect(store.read_state).to eq(123)
  end

  it 'mutator instance method definition' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store)
    Store.mutator(:write_state) { @state = 987 }
    expect(store.write_state).to eq(987)
    expect(store.instance_eval { @state }).to eq(987)
  end

  it 'state_accessor instance method definition' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(store)
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store)
    Store.state_accessor(:state)
    store.state = 777
    expect(store.state).to eq(777)
    expect(store.instance_eval { @state }).to eq(777)
  end

  it 'state_reader instance method definition' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(store)
    Store.state_reader(:state)
    store.instance_eval { @state = 999 }
    expect(store.state).to eq(999)
  end

  it 'state_writer instance method definition' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(store)
    Store.state_accessor(:state)
    store.state = 777
    expect(store.instance_eval { @state }).to eq(777)
  end

  it 'observer class method definition' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(Store)
    Store.singleton_class.observer(:read_state) { @state }
    Store.instance_eval { @state = 123 }
    expect(Store.read_state).to eq(123)
  end

  it 'mutator class method definition' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(Store)
    Store.singleton_class.mutator(:write_state) { @state = 987 }
    expect(Store.write_state).to eq(987)
    expect(Store.instance_eval { @state }).to eq(987)
  end

  it 'state_accessor class method definition' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(Store)
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(Store)
    Store.singleton_class.state_accessor(:state)
    Store.state = 777
    expect(Store.state).to eq(777)
    expect(Store.instance_eval { @state }).to eq(777)
  end

  it 'state_reader class method definition' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).with(Store)
    Store.singleton_class.state_reader(:state)
    Store.instance_eval { @state = 999 }
    expect(Store.state).to eq(999)
  end

  it 'state_writer class method definition' do
    expect(Hyperstack::Internal::State::Mapper).to receive(:mutated!).with(Store)
    Store.singleton_class.state_accessor(:state)
    Store.state = 777
    expect(Store.instance_eval { @state }).to eq(777)
  end
end
