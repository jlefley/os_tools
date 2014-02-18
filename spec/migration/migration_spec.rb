require 'spec_helper'

describe OSTools::Migration do
  
  describe 'when copying migrations' do
   
    def clear migrations_path, existing_migrations
      to_delete = Dir[migrations_path + "/*.rb"] - existing_migrations
      File.delete(*to_delete)
    end

    let(:root) { File.expand_path('../migrations', __FILE__) }

    describe 'without timestamps' do
      let(:migrations_path) { root + '/valid' }
      let!(:existing_migrations) { Dir[migrations_path + '/*.rb'] }
     
      before do
        @copied = OSTools::Migration.copy(migrations_path, { bukkits: root + '/to_copy' })
      end

      after { clear migrations_path, existing_migrations }

      it 'should copy migrations to the destination and increment versions above existing migrations' do
        File.exist?(migrations_path + '/4_people_have_hobbies.bukkits.rb').should == true
        File.exist?(migrations_path + '/5_people_have_descriptions.bukkits.rb').should == true
      end
      it 'should return copied migrations' do
        copied = [migrations_path + '/4_people_have_hobbies.bukkits.rb', migrations_path + '/5_people_have_descriptions.bukkits.rb']
        copied.should == @copied.map(&:filename)
      end
      it 'should add comment to copied migrations indicating source' do
        expected = '# This migration comes from bukkits (originally 1)'
        IO.readlines(migrations_path + "/4_people_have_hobbies.bukkits.rb")[0].chomp.should == expected
      end
      it 'should not copy migrations when after they have already been copied' do
        files_count = Dir[migrations_path + "/*.rb"].length
        copied = OSTools::Migration.copy(migrations_path, { bukkits: root + '/to_copy' })
        Dir[migrations_path + '/*.rb'].length.should == files_count
        copied.should be_empty
      end
    
    end
    describe 'without timestamps from 2 sources' do
      let(:migrations_path) { root + '/valid' }
      let!(:existing_migrations) { Dir[migrations_path + '/*.rb'] }
      let(:sources) { ActiveSupport::OrderedHash.new }

      before do
        sources[:bukkits] = root + '/to_copy'
        sources[:omg] = root + '/to_copy2'
        OSTools::Migration.copy(migrations_path, sources) 
      end
      
      after { clear migrations_path, existing_migrations }

      it 'should copy migrations from both sources to the destination and increment versions above existing migrations' do
        File.exists?(migrations_path + '/4_people_have_hobbies.bukkits.rb').should == true
        File.exists?(migrations_path + '/5_people_have_descriptions.bukkits.rb').should == true
        File.exists?(migrations_path + '/6_create_articles.omg.rb').should == true
        File.exists?(migrations_path + '/7_create_comments.omg.rb').should == true 
      end
      it 'should not copy migrations when after they have already been copied' do
        files_count = Dir[migrations_path + '/*.rb'].length
        copied = OSTools::Migration.copy(migrations_path, sources)
        Dir[migrations_path + '/*.rb'].length.should == files_count
        copied.should be_empty
      end

    end
    describe 'with timestamps' do
    end
    describe 'with timestamps from 2 sources' do
    end
    describe 'with timestamps to destination with timestamps in future' do
    end
    describe 'when migrations exist in destination' do
      let(:migrations_path) { root + '/valid' }
      let!(:existing_migrations) { Dir[migrations_path + '/*.rb'] }
      let(:skipped) { [] }

      before do
        on_skip = Proc.new { |name, migration| skipped << "#{name} #{migration.name}" }
        sources = ActiveSupport::OrderedHash.new
        sources[:bukkits] = root + '/to_copy'
        sources[:omg] = root + '/to_copy_with_name_collision'
        @copied = OSTools::Migration.copy(migrations_path, sources, :on_skip => on_skip)
      end
      
      after { clear migrations_path, existing_migrations }

      it 'should copy the migrations from the first source' do
        @copied.length.should == 2
      end

      it 'should skip migrations with duplicate name' do
        skipped.length.should == 1
        skipped.should == ['omg PeopleHaveHobbies']
      end
    end
    describe 'when migrations are copied after already having been copied' do
      let(:migrations_path) { root + '/valid' }
      let!(:existing_migrations) { Dir[migrations_path + '/*.rb'] }
      let(:skipped) { [] }
      let(:copied) { [] }

      before do
        on_skip =  Proc.new { |name, migration| skipped << "#{name} #{migration.name}" }
        on_copy = Proc.new { |name, migration| copied << "#{name} #{migration.name}" }
        OSTools::Migration.copy(migrations_path, { bukkits: root + '/to_copy' }, on_copy: on_copy, on_skip: on_skip) 
        OSTools::Migration.copy(migrations_path, { bukkits: root + '/to_copy' }, on_copy: on_copy, on_skip: on_skip) 
      end
      
      after { clear migrations_path, existing_migrations }

      it 'should not call on_skip' do
        skipped.should be_empty
      end
      it 'should call on_copy' do
        copied.length.should == 2
      end
    end
    
    describe 'when destination directory does not exist' do
      let(:migrations_path) { root + '/non_existing' }
      let!(:existing_migrations) { [] }
     
      before do
        @copied = OSTools::Migration.copy(migrations_path, { bukkits: root + '/to_copy' })
      end

      after do
        clear migrations_path, existing_migrations
        Dir.delete(migrations_path)
      end

      it 'should copy the migrations into a new directory correspoinding to the specified destination' do
        File.exist?(migrations_path + '/1_people_have_hobbies.bukkits.rb').should == true
        File.exist?(migrations_path + '/2_people_have_descriptions.bukkits.rb').should == true
        @copied.length.should == 2
      end
    end
  end
end
