RSpec.describe Hyrax::MenuPresenter do
  let(:instance) { described_class.new(context) }
  let(:context) { ActionView::TestCase::TestController.new.view_context }
  let(:controller_name) { controller.controller_name }

  describe "#settings_section?" do
    before do
      allow(context).to receive(:controller_name).and_return(controller_name)
    end
    subject { instance.settings_section? }

    context "for the ContentBlocksController" do
      let(:controller_name) { Hyrax::ContentBlocksController.controller_name }

      it { is_expected.to be true }
    end
    context "for the PagesController" do
      let(:controller_name) { Hyrax::PagesController.controller_name }

      it { is_expected.to be true }
    end
    context "for the CollectionTypesController" do
      let(:controller_name) { Hyrax::Admin::CollectionTypesController.controller_name }

      it { is_expected.to be true }
    end
  end

  describe "#collapsable_section" do
    subject do
      instance.collapsable_section('link title',
                                   id: 'mySection',
                                   icon_class: 'fa fa-cog',
                                   open: open) do
                                     "Some content"
                                   end
    end

    let(:rendered) { Capybara::Node::Simple.new(subject) }

    context "when collapsed" do
      let(:open) { false }

      it "draws a collapsable section" do
        expect(rendered).to have_content "Some content"
        expect(rendered).to have_selector "span.fa.fa-cog"
        expect(rendered).to have_selector "a.collapsed.collapse-toggle[href='#mySection']"
        expect(rendered).to have_selector "ul#mySection"
      end
    end

    context "when open" do
      let(:open) { true }

      it "draws a collapsable section" do
        expect(rendered).to have_content "Some content"
        expect(rendered).to have_selector "span.fa.fa-cog"
        expect(rendered).to have_selector "a.collapse-toggle[href='#mySection']"
        expect(rendered).to have_selector "ul#mySection.in"
      end
    end
  end

  describe "#user_activity_section?" do
    before do
      allow(context).to receive(:controller_name).and_return(controller_name)
      allow(context).to receive(:controller).and_return(controller)
    end
    subject { instance.user_activity_section? }

    context "for the Hyrax::UsersController" do
      let(:controller) { Hyrax::UsersController.new }

      it { is_expected.to be true }
    end

    context "for the Admin::UsersController" do
      let(:controller) { Hyrax::Admin::UsersController.new }

      it { is_expected.to be false }
    end

    context "for the Hyrax::DepositorsController" do
      let(:controller) { Hyrax::DepositorsController.new }

      it { is_expected.to be true }
    end
  end

  describe "#admin_reports_section?" do
    before do
      allow(context).to receive(:controller_name).and_return(controller_name)
      allow(context).to receive(:action_name).and_return(action_name)
    end
    subject { instance.admin_reports_section? }

    context "for the Admin::Reports::WorksController" do
      let(:controller_name) { Hyrax::Admin::Reports::WorksController.controller_name }

      context "status action" do
        let(:action_name) { 'status' }

        it { is_expected.to be true }
      end

      context "attributes action" do
        let(:action_name) { 'attributes' }

        it { is_expected.to be true }
      end

      context "activity action" do
        let(:action_name) { 'activity' }

        it { is_expected.to be true }
      end

      context "show action" do
        let(:action_name) { 'show' }

        it { is_expected.to be false }
      end
    end
  end

  describe "#admin_reports_works_section?" do
    before { allow(context).to receive(:controller).and_return(controller) }
    subject { instance.admin_reports_works_section? }

    context "for the Admin::Reports::Works::WorkController" do
      let(:controller) { Hyrax::Admin::Reports::WorksController.new }

      it { is_expected.to be true }
    end
  end

  describe "#show_configuration?" do
    subject { instance.show_configuration? }

    context "for a regular user" do
      before do
        allow(instance.view_context).to receive(:can?).and_return(false)
      end
      it { is_expected.to be false }
    end

    context "for a user who can manage users" do
      before do
        allow(instance.view_context).to receive(:can?).and_return(true)
      end
      it { is_expected.to be true }
    end
  end
end
