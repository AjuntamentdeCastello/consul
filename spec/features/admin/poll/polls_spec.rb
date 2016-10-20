require 'rails_helper'

feature 'Admin polls' do

  background do
    admin = create(:administrator)
    login_as(admin.user)
  end

  scenario 'Index empty' do
    visit admin_root_path
    within('#side_menu') do
      click_link "Polls"
    end

    expect(page).to have_content "There are no polls"
  end

  scenario 'Index' do
    3.times { create(:poll) }

    visit admin_root_path

    within('#side_menu') do
      click_link "Polls"
    end

    expect(page).to have_css ".poll", count: 3

    polls = Poll.all
    polls.each do |poll|
      within("#poll_#{poll.id}") do
        expect(page).to have_content poll.name
      end
    end
    expect(page).to_not have_content "There are no polls"
  end

  scenario 'Show' do
    poll = create(:poll)

    visit admin_polls_path
    click_link poll.name

    expect(page).to have_content poll.name
  end

  scenario "Create" do
    visit admin_polls_path
    click_link "Create poll"

    fill_in "poll_name", with: "Upcoming poll"
    click_button "Create poll"

    expect(page).to have_content "Poll created successfully"
    expect(page).to have_content "Upcoming poll"
  end

  scenario "Edit" do
    poll = create(:poll)

    visit admin_poll_path(poll)
    click_link "Edit"

    fill_in "poll_name", with: "Next Poll"
    click_button "Update poll"

    expect(page).to have_content "Poll updated successfully"
    expect(page).to have_content "Next Poll"
  end

  scenario 'Edit from index' do
    poll = create(:poll)
    visit admin_polls_path

    within("#poll_#{poll.id}") do
      click_link "Edit"
    end

    expect(current_path).to eq(edit_admin_poll_path(poll))
  end

  context "Booths" do

    context "Poll show" do

      scenario "No booths" do
        poll = create(:poll)
        visit admin_poll_path(poll)

        expect(page).to have_content "There are no booths in this poll."
      end

      scenario "Booth list" do
        poll = create(:poll)
        3.times { create(:poll_booth, poll: poll) }

        visit admin_poll_path(poll)

        expect(page).to have_css ".booth", count: 3

        booths = Poll::Booth.all
        booths.each do |booth|
          within("#booth_#{booth.id}") do
            expect(page).to have_content booth.name
            expect(page).to have_content booth.location
          end
        end
        expect(page).to_not have_content "There are no booths"
      end

      scenario "Add booth" do
        poll = create(:poll)
        visit admin_poll_path(poll)

        click_link "Add booth"

        expect(current_path).to eq(new_admin_poll_booth_path(poll))
        expect(page).to have_content poll.name
      end
    end
  end

end