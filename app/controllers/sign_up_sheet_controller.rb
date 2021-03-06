# contains all functions related to management of the signup sheet for an assignment
# functions to add new topics to an assignment, edit properties of a particular topic, delete a topic, etc
# are included here

# A point to be taken into consideration is that :id (except when explicitly stated) here means topic id and not assignment id
# (this is referenced as :assignment id in the params has)
# The way it works is that assignments have their own id's, so do topics. A topic has a foreign key dependecy on the assignment_id
# Hence each topic has a field called assignment_id which points which can be used to identify the assignment that this topic belongs
# to

class SignUpSheetController < ApplicationController
  require 'rgl/adjacency'
  require 'rgl/dot'
  require 'rgl/topsort'
  #The rescue operations are added for our Ajax Calls that are made to this controller for loading data in Topics page
  rescue_from ::ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ::NameError, with: :error_occurred

  def record_not_found(exception)
    render json: {error: exception.message}.to_json, status: 404
    return
  end

  def error_occurred(exception)
    render json: {error: exception.message}.to_json, status: 500
    return
  end

  def action_allowed?
    case params[:action]
    when 'set_priority', 'sign_up', 'delete_signup', 'list', 'show_team', 'switch_original_topic_to_approved_suggested_topic', 'publish_approved_suggested_topic'
      ['Instructor',
       'Teaching Assistant',
       'Administrator',
       'Super-Administrator',
       'Student'].include? current_role_name and
      ((%w(list).include? action_name) ? are_needed_authorizations_present?(params[:id], "reader", "submitter", "reviewer") : true)
    else
      ['Instructor',
       'Teaching Assistant',
       'Administrator',
       'Super-Administrator'].include? current_role_name
    end
  end

  # Includes functions for team management. Refer /app/helpers/ManageTeamHelper
  include ManageTeamHelper
  # Includes functions for Dead line management. Refer /app/helpers/DeadLineHelper
  include DeadlineHelper

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify method: :post, only: [:destroy, :create, :update],
         redirect_to: {action: :list}

  # Prepares the form for adding a new topic. Used in conjunction with create
  def new
    @id = params[:id]
    @sign_up_topic = SignUpTopic.new
    @sign_up_topic.assignment = Assignment.find(params[:id])
    @topic = @sign_up_topic
  end

  # This method is used to create signup topics
  # In this code params[:id] is the assignment id and not topic id. The intuition is
  # that assignment id will virtually be the signup sheet id as well as we have assumed
  # that every assignment will have only one signup sheet
  def create
    # the params are received through Ajax requests rather than form submits.
    # Thus parameters are given directly than ruby hashes.
    topic = SignUpTopic.where(topic_name: params[:topic_name], assignment_id: params[:id]).first
    # if the topic already exists then update
    if topic == nil
      setup_new_topic
    else
      update_existing_topic topic
    end
  end

  # This method is used to delete signup topics
  # Renaming delete method to destroy for rails 4 compatible
  def destroy
    @topic = SignUpTopic.find(params[:id])
    if @topic
      @topic.destroy
      # undo_link("The topic: \"#{@topic.topic_name}\" has been successfully deleted. ")
    else
      render json: {error: 'FAIL'} , :status => 404
    end
    # All the CRUD operations in topics page are ajax based on json responses. Thus we will be responding with JSON.
    render json: {status: 'PASS'}

  end

  # prepares the page. shows the form which can be used to enter new values for the different properties of an assignment
  def edit
    @topic = SignUpTopic.find(params[:id])
  end

  # updates the database tables to reflect the new values for the assignment. Used in conjuntion with edit
  def update
    @topic = SignUpTopic.find(params[:id])
    if @topic
      @topic.topic_identifier = params[:topic_identifier]
      if !update_max_choosers @topic
        # We are setting up the response code to 400 if we encounter this criteria so that it can be handled if Ajax call fails in the front end.
        render json: {error: 'FAIL' , flash: 'The value of the maximum number of choosers can only be increased! No change has been made to maximum choosers.'}.to_json, status: 400
      else
        # update tables
        #All the following parameters are send through data in Ajax in updateItem.
        @topic.category = params[:category]
        @topic.topic_name = params[:topic_name]
        @topic.micropayment = params[:micropayment]
        @topic.description = params[:description]
        @topic.link = params[:link]
        @topic.save
        render :json => @topic.as_json
      end
    else
      render json: {error: 'FAIL'}, :status => 404
    end
    # changing the redirection url to topics tab in edit assignment view.
  end
  # This displays a page that lists all the available topics for an assignment.
  # Contains links that let an admin or Instructor edit, delete, view enrolled/waitlisted members for each topic
  # Also contains links to delete topics and modify the deadlines for individual topics. Staggered means that different topics can have different deadlines.
  # issue 971 - do enable ajax control
  # 1781
  # see Js Grid for json format to insert in the model
  def add_signup_topics
    SignUpSheet.add_signup_topic(params[:id]) #model call - just a get query .. nothing to do with add
  end

  def add_signup_topics_staggered
    add_signup_topics
  end

  # retrieves all the data associated with the given assignment. Includes all topics,
  # this should retrieve results in Json so that it can be ajaxed
  # 1781
  # the following method is an action which renders all the topics of an assignment in the JSON format.
  def load_add_signup_topics
    @id = params[:id]
    assignment_id =  params[:id]
    @sign_up_topics = SignUpTopic.where('assignment_id = ?', assignment_id)
    @slots_filled = SignUpTopic.find_slots_filled(assignment_id)
    @slots_waitlisted = SignUpTopic.find_slots_waitlisted(assignment_id)
    @assignment = Assignment.find(assignment_id)
    @participants = SignedUpTeam.find_team_participants(assignment_id)
    # colloborating for JSON
    @sign_up_topics.each {|topic|
      topic_id = topic.id
      slots_fill_temp = 0
      slots_waitlisted = 0
      participants = []
      if @slots_filled
        @slots_filled.each {|slot|
          if slot.topic_id == topic_id
            slots_fill_temp = slot.count
          end
        }
      end
      if @slots_waitlisted
        @slots_waitlisted.each {|slot|
          if slot.topic_id == topic_id
            slots_waitlisted = slot.count
          end
        }
      end
      if @participants
        @participants.each {|participant|
          if participant.topic_id == topic_id

            participants << participant
          end
        }
      end
      topic.slots_filled_value = slots_fill_temp
      topic.slots_waitlisted = slots_waitlisted
      topic.slots_available = topic.max_choosers - topic.slots_filled_value
      topic.partipants = participants
    }
    # ACS Removed the if condition (and corresponding else) which differentiate assignments as team and individual assignments
    # to treat all assignments as team assignments
    # Though called participants, @participants are actually records in signed_up_teams table, which
    # is a mapping table between teams and topics (waitlisted recored are also counted)
    render :json => {
      :id => @id.as_json,
      :sign_up_topics => @sign_up_topics.as_json( :methods => [:slots_filled_value,:slots_waitlisted,:slots_available,:partipants]),
      :slots_waitlisted => @slots_waitlisted.as_json,
      :assignment => @assignment.as_json
    }
  end

  # All the parameters are sent through data object in the Ajax insert call
  def set_values_for_new_topic
    @sign_up_topic = SignUpTopic.new
    @sign_up_topic.topic_identifier = params[:topic_identifier]
    @sign_up_topic.topic_name = params[:topic_name]
    @sign_up_topic.max_choosers = params[:max_choosers]
    @sign_up_topic.category = params[:category]
    @sign_up_topic.assignment_id = params[:id]
    @sign_up_topic.description =params[:description]
    @sign_up_topic.link =params[:link]
    @assignment = Assignment.find(params[:id])
  end

  # simple function that redirects ti the /add_signup_topics or the /add_signup_topics_staggered page depending on assignment type
  # staggered means that different topics can have different deadlines.
  def redirect_to_sign_up(assignment_id)
    assignment = Assignment.find(assignment_id)
    (assignment.staggered_deadline == true) ? (redirect_to action: 'add_signup_topics_staggered', id: assignment_id) : (redirect_to action: 'add_signup_topics', id: assignment_id)
  end

  # simple function that redirects to assignment->edit->topic panel to display /add_signup_topics or the /add_signup_topics_staggered page
  # staggered means that different topics can have different deadlines.
  def redirect_to_assignment_edit(assignment_id)
    assignment = Assignment.find(assignment_id)
    redirect_to controller: 'assignments', action: 'edit', id: assignment_id
  end

  def list
    @participant = AssignmentParticipant.find(params[:id].to_i)
    @assignment = @participant.assignment
    @slots_filled = SignUpTopic.find_slots_filled(@assignment.id)
    @slots_waitlisted = SignUpTopic.find_slots_waitlisted(@assignment.id)
    @show_actions = true
    @priority = 0
    @sign_up_topics = SignUpTopic.where(assignment_id: @assignment.id, private_to: nil)
    @max_team_size = @assignment.max_team_size
    team_id = @participant.team.try(:id)

    if @assignment.is_intelligent
      @bids = team_id.nil? ? [] : Bid.where(team_id: team_id).order(:priority) 
      signed_up_topics = []
      @bids.each do |bid|
        sign_up_topic = SignUpTopic.find_by(id: bid.topic_id)
        signed_up_topics << sign_up_topic if sign_up_topic
      end
      signed_up_topics &= @sign_up_topics
      @sign_up_topics -= signed_up_topics
      @bids = signed_up_topics
    end

    @num_of_topics = @sign_up_topics.size
    @signup_topic_deadline = @assignment.due_dates.find_by_deadline_type_id(7)
    @drop_topic_deadline = @assignment.due_dates.find_by_deadline_type_id(6)
    @student_bids = team_id.nil? ? [] : Bid.where(team_id: team_id)

    unless @assignment.due_dates.find_by_deadline_type_id(1).nil?
      if !@assignment.staggered_deadline? and @assignment.due_dates.find_by_deadline_type_id(1).due_at < Time.now
        @show_actions = false
      end

      # Find whether the user has signed up for any topics; if so the user won't be able to
      # sign up again unless the former was a waitlisted topic
      # if team assignment, then team id needs to be passed as parameter else the user's id
      users_team = SignedUpTeam.find_team_users(@assignment.id, session[:user].id)
      @selected_topics = if users_team.empty?
                           nil
                         else
                           # TODO: fix this; cant use 0
                           SignedUpTeam.find_user_signup_topics(@assignment.id, users_team[0].t_id)
                         end
    end
    if @assignment.is_intelligent
      render 'sign_up_sheet/intelligent_topic_selection' and return
    end
  end

  def sign_up
    @assignment = AssignmentParticipant.find(params[:id]).assignment
    @user_id = session[:user].id
    # Always use team_id ACS
    # s = Signupsheet.new
    # Team lazy initialization: check whether the user already has a team for this assignment
    unless SignUpSheet.signup_team(@assignment.id, @user_id, params[:topic_id])
      flash[:error] = "You've already signed up for a topic!"
    end
    redirect_to action: 'list', id: params[:id]
  end

  # routes to new page to specficy student
  def signup_as_instructor; end

  def signup_as_instructor_action
    user = User.find_by(name: params[:username])
    if user.nil? # validate invalid user
      flash[:error] = "That student does not exist!"
    else
      if AssignmentParticipant.exists? user_id: user.id, parent_id: params[:assignment_id]
        if SignUpSheet.signup_team(params[:assignment_id], user.id, params[:topic_id])
          flash[:success] = "You have successfully signed up the student for the topic!"
        else
          flash[:error] = "The student has already signed up for a topic!"
        end
      else
        flash[:error] = "The student is not registered for the assignment!"
      end
    end
    redirect_to controller: 'assignments', action: 'edit', id: params[:assignment_id]
  end

  # this function is used to delete a previous signup
  def delete_signup
    participant = AssignmentParticipant.find(params[:id])
    assignment = participant.assignment
    drop_topic_deadline = assignment.due_dates.find_by_deadline_type_id(6)
    # A student who has already submitted work should not be allowed to drop his/her topic!
    # (A student/team has submitted if participant directory_num is non-null or submitted_hyperlinks is non-null.)
    # If there is no drop topic deadline, student can drop topic at any time (if all the submissions are deleted)
    # If there is a drop topic deadline, student cannot drop topic after this deadline.
    if !participant.team.submitted_files.empty? or !participant.team.hyperlinks.empty?
      flash[:error] = "You have already submitted your work, so you are not allowed to drop your topic."
    elsif !drop_topic_deadline.nil? and Time.now > drop_topic_deadline.due_at
      flash[:error] = "You cannot drop your topic after the drop topic deadline!"
    else
      delete_signup_for_topic(assignment.id, params[:topic_id], session[:user].id)
      flash[:success] = "You have successfully dropped your topic!"
    end
    redirect_to action: 'list', id: params[:id]
  end

  def delete_signup_as_instructor
    # find participant using assignment using team and topic ids
    team = Team.find(params[:id])
    assignment = Assignment.find(team.parent_id)
    user = TeamsUser.find_by(team_id: team.id).user
    participant = AssignmentParticipant.find_by(user_id: user.id, parent_id: assignment.id)
    drop_topic_deadline = assignment.due_dates.find_by_deadline_type_id(6)
    if !participant.team.submitted_files.empty? or !participant.team.hyperlinks.empty?
      flash[:error] = "The student has already submitted their work, so you are not allowed to remove them."
    elsif !drop_topic_deadline.nil? and Time.now > drop_topic_deadline.due_at
      flash[:error] = "You cannot drop a student after the drop topic deadline!"
    else
      delete_signup_for_topic(assignment.id, params[:topic_id], participant.user_id)
      flash[:success] = "You have successfully dropped the student from the topic!"
    end
    redirect_to controller: 'assignments', action: 'edit', id: assignment.id
  end

  def set_priority
    participant = AssignmentParticipant.find_by(id: params[:participant_id])
    assignment_id = SignUpTopic.find(params[:topic].first).assignment.id
    team_id = participant.team.try(:id)
    unless team_id
      # Zhewei: team lazy initialization
      SignUpSheet.signup_team(assignment_id, participant.user.id)
      team_id = participant.team.try(:id)
    end
    if params[:topic].nil?
      # All topics are deselected by current team
      Bid.where(team_id: team_id).destroy_all
    else
      @bids = Bid.where(team_id: team_id)
      signed_up_topics = Bid.where(team_id: team_id).map(&:topic_id)
      # Remove topics from bids table if the student moves data from Selection table to Topics table
      # This step is necessary to avoid duplicate priorities in Bids table
      signed_up_topics -= params[:topic].map(&:to_i)
      signed_up_topics.each do |topic|
        Bid.where(topic_id: topic, team_id: team_id).destroy_all
      end
      params[:topic].each_with_index do |topic_id, index|
        bid_existence = Bid.where(topic_id: topic_id, team_id: team_id)
        if bid_existence.empty?
          Bid.create(topic_id: topic_id, team_id: team_id, priority: index + 1)
        else
          Bid.where(topic_id: topic_id, team_id: team_id).update_all(priority: index + 1)
        end
      end
    end
    redirect_to action: 'list', assignment_id: params[:assignment_id]
  end

  # If the instructor needs to explicitly change the start/due dates of the topics
  # This is true in case of a staggered deadline type assignment. Individual deadlines can
  # be set on a per topic and per round basis
  def save_topic_deadlines
    assignment = Assignment.find(params[:assignment_id])
    @assignment_submission_due_dates = assignment.due_dates.select {|due_date| due_date.deadline_type_id == 1 }
    @assignment_review_due_dates = assignment.due_dates.select {|due_date| due_date.deadline_type_id == 2 }
    due_dates = params[:due_date]
    topics = SignUpTopic.where(assignment_id: params[:assignment_id])
    review_rounds = assignment.num_review_rounds
    topics.each_with_index do |topic, index|
      for i in 1..review_rounds
        @topic_submission_due_date = due_dates[topics[index].id.to_s + '_submission_' + i.to_s + '_due_date']
        @topic_review_due_date = due_dates[topics[index].id.to_s + '_review_' + i.to_s + '_due_date']
        @assignment_submission_due_date = DateTime.parse(@assignment_submission_due_dates[i - 1].due_at.to_s).strftime("%Y-%m-%d %H:%M")
        @assignment_review_due_date = DateTime.parse(@assignment_review_due_dates[i - 1].due_at.to_s).strftime("%Y-%m-%d %H:%M")
        %w(submission review).each do |deadline_type|
          deadline_type_id = DeadlineType.find_by_name(deadline_type).id
          next if instance_variable_get('@topic_' + deadline_type + '_due_date') == instance_variable_get('@assignment_' + deadline_type + '_due_date')
          topic_due_date = TopicDueDate.where(parent_id: topic.id, deadline_type_id: deadline_type_id, round: i).first rescue nil
          if topic_due_date.nil? # create a new record
            TopicDueDate.create(
              due_at:                      instance_variable_get('@topic_' + deadline_type + '_due_date'),
              deadline_type_id:            deadline_type_id,
              parent_id:                   topic.id,
              submission_allowed_id:       instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].submission_allowed_id,
              review_allowed_id:           instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].review_allowed_id,
              review_of_review_allowed_id: instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].review_of_review_allowed_id,
              round:                       i,
              flag:                        instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].flag,
              threshold:                   instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].threshold,
              delayed_job_id:              instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].delayed_job_id,
              deadline_name:               instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].deadline_name,
              description_url:             instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].description_url,
              quiz_allowed_id:             instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].quiz_allowed_id,
              teammate_review_allowed_id:  instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].teammate_review_allowed_id,
              type:                       'TopicDueDate'
            )
          else # update an existed record
            topic_due_date.update_attributes(
              due_at:                      instance_variable_get('@topic_' + deadline_type + '_due_date'),
              submission_allowed_id:       instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].submission_allowed_id,
              review_allowed_id:           instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].review_allowed_id,
              review_of_review_allowed_id: instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].review_of_review_allowed_id,
              quiz_allowed_id:             instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].quiz_allowed_id,
              teammate_review_allowed_id:  instance_variable_get('@assignment_' + deadline_type + '_due_dates')[i - 1].teammate_review_allowed_id
            )
          end
        end
      end
    end
    redirect_to_assignment_edit(params[:assignment_id])
  end

  # This method is called when a student click on the trumpet icon. So this is a bad method name. --Yang
  def show_team
    if !(assignment = Assignment.find(params[:assignment_id])).nil? and !(topic = SignUpTopic.find(params[:id])).nil?
      @results = ad_info(assignment.id, topic.id)
      @results.each do |result|
        result.keys.each do |key|
          @current_team_name = result[key] if key.equal? :name
        end
      end
      @results.each do |result|
        @team_members = ""
        TeamsUser.where(team_id: result[:team_id]).each do |teamuser|
          @team_members += User.find(teamuser.user_id).name + " "
        end
      end
      # @team_members = find_team_members(topic)
    end
  end

  def switch_original_topic_to_approved_suggested_topic
    assignment = AssignmentParticipant.find(params[:id]).assignment
    team_id = TeamsUser.team_id(assignment.id, session[:user].id)
    original_topic_id = SignedUpTeam.topic_id(assignment.id.to_i, session[:user].id)
    SignUpTopic.find(params[:topic_id]).update_attribute('private_to', nil) if SignUpTopic.exists?(params[:topic_id])
    if SignedUpTeam.exists?(team_id: team_id, is_waitlisted: 0)
      SignedUpTeam.where(team_id: team_id, is_waitlisted: 0).first.update_attribute('topic_id', params[:topic_id].to_i)
    end
    # check the waitlist of original topic. Let the first waitlisted team hold the topic, if exists.
    waitlisted_teams = SignedUpTeam.where(topic_id: original_topic_id, is_waitlisted: 1)
    unless waitlisted_teams.blank?
      waitlisted_first_team_first_user_id = TeamsUser.where(team_id: waitlisted_teams.first.team_id).first.user_id
      SignUpSheet.signup_team(assignment.id, waitlisted_first_team_first_user_id, original_topic_id)
    end
    redirect_to action: 'list', id: params[:id]
  end

  def publish_approved_suggested_topic
    SignUpTopic.find(params[:topic_id]).update_attribute('private_to', nil) if SignUpTopic.exists?(params[:topic_id])
    redirect_to action: 'list', id: params[:id]
  end

  private
  
  def setup_new_topic
    set_values_for_new_topic
    if @assignment.microtask?
      @sign_up_topic.micropayment = params[:micropayment]
    end
    if @assignment.staggered_deadline?
      topic_set = []
      topic = @sign_up_topic.id
    end
    if !@sign_up_topic.save
     # undo_link "The topic: \"#{@sign_up_topic.topic_name}\" has been created successfully. "
     # changing the redirection url to topics tab in edit assignment view.
     render json: {error: 'FAIL'}, :status => 404
    else
      render json: @sign_up_topic.as_json
    end
  end

  def update_existing_topic(topic)
    topic.topic_identifier = params[:topic_identifier]
    if !update_max_choosers topic
      render json: {error: 'FAIL' , flash: 'The value of the maximum number of choosers can only be increased! No change has been made to maximum choosers.'}.to_json, status: 400
    else
      topic.category = params[:category]
      # topic.assignment_id = params[:id]
      topic.save
      render json: topic.as_json
    end
  end

  def update_max_choosers(topic)
    # While saving the max choosers you should be careful; if there are users who have signed up for this particular
    # topic and are on waitlist, then they have to be converted to confirmed topic based on the availability. But if
    # there are choosers already and if there is an attempt to decrease the max choosers, as of now I am not allowing
    # it.
    if SignedUpTeam.find_by_topic_id(topic.id).nil? || topic.max_choosers == params[:max_choosers]
      topic.max_choosers = params[:max_choosers]
    else
      if topic.max_choosers.to_i < params[:max_choosers].to_i
        topic.update_waitlisted_users params[:max_choosers]
        topic.max_choosers = params[:max_choosers]
      else
        flash[:error] = "The value of the maximum number of choosers can only be increased! No change has been made to maximum choosers."
        return false
      end
    end
    true
  end

  # get info related to the ad for partners so that it can be displayed when an assignment_participant
  # clicks to see ads related to a topic
  def ad_info(_assignment_id, topic_id)
    # List that contains individual result object
    @result_list = []
    # Get the results
    @results = SignedUpTeam.where("topic_id = ?", topic_id.to_s)
    # Iterate through the results of the query and get the required attributes
    @results.each do |result|
      team = result.team
      topic = result.topic
      resultMap = {}
      resultMap[:team_id] = team.id
      resultMap[:comments_for_advertisement] = team.comments_for_advertisement
      resultMap[:name] = team.name
      resultMap[:assignment_id] = topic.assignment_id
      resultMap[:advertise_for_partner] = team.advertise_for_partner

      # Append to the list
      @result_list.append(resultMap)
    end
    @result_list
  end

  def delete_signup_for_topic(assignment_id, topic_id, user_id)
    SignUpTopic.reassign_topic(user_id, assignment_id, topic_id)
  end
end