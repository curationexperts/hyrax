require 'rails_helper'

RSpec.describe 'building a IIIF Manifest' do
  let(:work) { create(:work, title: ['Comet in Moominland'], creator: ['Jansson, Tove'], description: ['a novel about moomins']) }
  let(:member_works) { create_list(:work_with_image_files, 2, title: ['supplemental object'], creator: ['Author, Samantha'], description: ['supplemental materials']) }
  let(:file_sets) { create_list(:file_set, 12, :image, title: ['page n'], creator: ['Jansson, Tove'], description: ['the nth page']) }

  let(:user) { create(:admin) }

  before do
    work.ordered_members += file_sets
    work.members += member_works
    work.save

    sign_in user
  end

  it 'gets a full manifest for the work' do
    visit "/concern/generic_works/#{work.id}/manifest"

    # maybe validate this with https://github.com/IIIF/presentation-validator/blob/master/schema/iiif_3_0.json ?
    manifest_json = JSON.parse(page.body)

    expect(manifest_json['label']).to eq 'Comet in Moominland'
    expect(manifest_json['description']).to contain_exactly('a novel about moomins')
    expect(manifest_json['sequences']).not_to be_empty

    sequence = manifest_json['sequences'].first

    expect(sequence['canvases'].count).to eq 12
  end
end
