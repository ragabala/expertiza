Expertiza::Application.routes.draw do

  resources :user_pastebins
  resources :tag_prompts
  resources :track_notifications
  resources :notifications
  resources :submission_records
  get 'auth/:provider/callback', to: 'auth#google_login'
  get 'auth/failure', to: 'content_pages#view'
  post 'impersonate/impersonate', to: 'impersonate#impersonate'

  resources :answer_tags do
    collection do
      post :create_edit
    end
  end

  resources :bookmarks do
    collection do
      post :save_bookmark_rating_score
    end
  end

  resources :join_team_requests

  resources :admin do
    collection do
      get :list_super_administrators
      get :list_administrators
      get :list_instructors
      post :create_instructor
      get :remove_instructor
      post :remove_instructor
      get :show_instructor
    end
  end

  resources :advertise_for_partner do
    collection do
      get :edit
      get :remove
      post ':id', action: :update
    end
  end



  resources :advice do
    collection do
      post :save_advice
    end
  end

  resources :assessment360 do
    collection do
      get :one_course_all_assignments
      get :all_students_all_reviews
      get :one_student_all_reviews
      get :one_assignment_all_students
    end
  end

  resources :assignments do
    collection do
      get :delete
      get :associate_assignment_with_course
      get :copy
      get :toggle_access
      get :delayed_mailer
      get :list_submissions
      get :delete_delayed_mailer
      get :remove_assignment_from_course
    end
  end

  resources :auth do
    collection do
      post :login
      post :logout
    end
  end

  resources :content_pages do
    collection do
      get :list
      get ':page_name', action: :view
    end
  end

  resources :controller_actions do
    collection do
      get 'list'
      post ':id', action: :update
      get 'new_for'
    end
  end

  resources :course do
    collection do
      get :delete
      get :toggle_access
      get :copy
      get :view_teaching_assistants
      post :add_ta
      get :auto_complete_for_user_name
      post :remove_ta
    end
  end

  resources :course_evaluation do
    collection do
      get :list
    end
  end

  resources :eula do
    collection do
      get :accept
      get :decline
      get :display
    end
  end

  resources :export_file do
    collection do
      get :start
      get :export
      post :export
      post :exportdetails
    end
  end

  resources :grades do
    collection do
      get :view
      get :view_team
      get :view_reviewer
      get :view_my_scores
      get :view_my_scores_new
      get :instructor_review
      post :remove_hyperlink
      post :save_grade_and_comment_for_submission
    end
  end

  resources :impersonate do
    collection do
      get :start
      post :impersonate
    end
  end

  resources :import_file do
    collection do
      get :start
      post :import
    end
  end

  get '/import_file/import', controller: :import_file, action: :import

  resources :institution do
    collection do
      get :list
      get :show
      get :new
      post :create
      post ':id', action: :update
    end
  end

  resources :invitations do
    collection do
      get :cancel
      get :accept
      get :decline
    end
  end

  resources :join_team_requests do
    collection do
      post :decline
      get :edit
    end
  end

  resources 'late_policies'

  resources :markup_styles

  resources :menu_items do
    collection do
      get :move_down
      get :move_up
      get :new_for
      get :link
      get :list
    end
  end

  resources :participants do
    collection do
      get :add
      post :add
      get :auto_complete_for_user_name
      get :delete_assignment_participant
      get :list
      get :change_handle
      get :inherit
      get :bequeath_all
      post :delete
      get :inherit
      get :bequeath_all
      post :update_authorizations
      post :update_duties
      post :change_handle
      get :view_publishing_rights
    end
  end

  resources :password_retrieval do
    collection do
      get :forgotten
      get :reset_password
      post :send_password
      post :update_password
    end
  end

  resources :permissions, constraints: {id: /\d+/} do
    collection do
      get :list
      get ':id', action: :show
      post ':id', action: :update
      delete ':id', action: :destroy
    end
  end

  post '/plagiarism_checker_results/:id' => 'plagiarism_checker_comparison#save_results'

  resources :profile do
    collection do
      get :edit
    end
  end

  resources :publishing do
    collection do
      get :view
      post :update_publish_permissions
      post :set_publish_permission
      get :grant
      get :grant_with_private_key
      post :grant_with_private_key
      get :set_publish_permission
    end
  end

  resources :questionnaires do
    collection do
      get :copy
      get :new
      get :edit
      get :list
      post :list_questionnaires
      get :new_quiz
      post :select_questionnaire_type
      get :toggle_access
      get :view
      get :delete
      post :create
      post :create_quiz_questionnaire
      post :update_quiz
      post :add_new_questions
      post :save_all_questions
    end
  end

  resources :reputation_web_service do
    collection do
      get :client
      post :send_post_request
    end
  end

  resources :author_feedback_questionnaires, controller: :questionnaires
  resources :review_questionnaires, controller: :questionnaires
  resources :metareview_questionnaires, controller: :questionnaires
  resources :teammate_review_questionnaires, controller: :questionnaires
  resources :survey_questionnaires, controller: :questionnaires
  resources :assignment_survey_questionnaires, controller: :questionnaires
  resources :global_survey_questionnaires, controller: :questionnaires
  resources :course_survey_questionnaires, controller: :questionnaires
  resources :bookmarkrating_questionnaires, controller: :questionnaires

  resources :questions do
    collection do
      get :delete
      get :types
    end
  end

  resources :response do
    collection do
      get :new_feedback
      get :view
      post :delete
      get :remove_hyperlink
      get :saving
      get :redirection
      get :show_calibration_results_for_student
      post :custom_create
      get :pending_surveys
    end
  end

  resources :review_mapping do
    collection do
      post :add_metareviewer
      get :add_reviewer
      post :add_reviewer
      post :add_self_reviewer
      get :add_self_reviewer
      get :add_user_to_assignment
      get :assign_metareviewer_dynamically
      get :assign_reviewer_dynamically
      post :assign_reviewer_dynamically
      get :auto_complete_for_user_name
      get :delete_all_metareviewers
      get :delete_outstanding_reviewers
      get :delete_metareviewer
      get :delete_reviewer
      get :distribution
      get :list_mappings
      get :response_report
      post :response_report
      get :select_metareviewer
      get :select_reviewer
      get :select_mapping
      post :assign_quiz_dynamically
      post :assign_metareviewer_dynamically
      post :automatic_review_mapping
      post :automatic_review_mapping_staggered
      #E1600
      post :start_self_review
      post :save_grade_and_comment_for_reviewer
      get :unsubmit_review
    end
  end

  resources :roles do
    collection do
      get :list
      post ':id', action: :update
    end
  end

  resources :roles_permissions do
    collection do
      get :new_permission_for_role
    end
  end

  resources :sign_up_sheet do
    collection do
      get :signup
      get :delete_signup
      get :add_signup_topics
      get :add_signup_topics_staggered
      get :delete_signup
      get :edit
      get :list
      get :signup_topics
      get :signup
      get :sign_up
      get :team_details
      get :intelligent_sign_up
      get :intelligent_save
      get :signup_as_instructor
      get :intelligent_topic_selection
      post :signup_as_instructor_action
      post :set_priority
      post :save_topic_deadlines
    end
    member do
      get :load_add_signup_topics
    end
  end

  resources :site_controllers do
    collection do
      get 'list'
      get 'new_called'
    end
  end

  # resources :statistics do
  #   collection do
  #     get :list_surveys
  #     get :list
  #     get :view_responses
  #   end
  # end

  resources :student_quizzes do
    collection do
      post :student_quizzes
      get :index
      post :record_response
      get :finished_quiz
      get :take_quiz
      get :review_questions
    end
  end

  resources :student_review do
    collection do
      get :list
    end
  end

  resources :student_task do
    collection do
      get :list
      get :view
    end
  end


  resources :student_teams do

    collection do
      get :view
      get :edit
      get :remove_participant
      get :auto_complete_for_user_name
    end
  end

  resources :submitted_content do
    collection do
      get :download
      get :edit
      get :folder_action
      get :remove_hyperlink
      post :remove_hyperlink
      post :submit_file
      post :folder_action
      post :submit_hyperlink
      get :submit_hyperlink
      get :view
    end
  end

  resources :suggestion do
    collection do
      get :list
      post :submit
      post :student_submit
      post :update_suggestion
    end      
  end

  resources :survey do
    collection do
      get :assign
    end
  end

  resources :survey_deployment do
    collection do
      get :list
      get :delete
      post :delete # change
      get :reminder_thread
    end
  end

  resources :survey_response do
    collection do
      get :view_responses
    	get :begin_survey
    	get :comments
    end
  end

  resources :system_settings do
    collection do
      get :list
    end
  end

  resources :teams do
    collection do
      get :list
      #post ':id', action: :create_teams
      post :create_teams
      post :inherit
    end
  end

  resources :teams_users do
    collection do
      post :create
    end
  end

  resources :tree_display do
    collection do
      get ':action'
      post 'list'
      post 'children_node_ng'
      post 'children_node_2_ng'
      post 'bridge_to_is_available'
      get 'session_last_open_tab'
      get 'set_session_last_open_tab'
    end
  end

  resources :users, constraints: {id: /\d+/} do
    collection do
      get :list
      post :list
      post ':id', action: :update
      get :show_selection
      get :auto_complete_for_user_name
      get 'set_anonymized_view'
      get :keys
    end
  end

  get '/versions/search', controller: :versions, action: :search

  resources :versions do
    collection do
      delete '', action: :destroy_all
    end
  end
  post '/users/request_user_create', controller: :users, action: :request_user_create
  post '/users/create_approved_user', controller: :users, action: :create_approved_user
  get 'instructions/home'
  get '/users/show_selection', controller: :users, action: :show_selection
  get '/users/list', controller: :users, action: :list
  get '/menu/*name', controller: :menu_items, action: :link
  get ':page_name', controller: :content_pages, action: :view, method: :get
  get '/submitted_content/submit_hyperlink' => 'submitted_content#submit_hyperlink'

  root to: 'content_pages#view', page_name: 'home'

  get 'users/list', :to => 'users#list'
  get '/submitted_content/remove_hyperlink', :to => 'submitted_content#remove_hyperlink'
  get '/submitted_content/submit_hyperlink', :to => 'submitted_content#submit_hyperlink'
  get '/submitted_content/submit_file', :to => 'submitted_content#submit_file'
  get '/review_mapping/assign_reviewer_dynamically', :to => 'review_mapping#assign_reviewer_dynamically'
  get '/review_mapping/assign_metareviewer_dynamically', :to => 'review_mapping#assign_metareviewer_dynamically'
  get 'response/', :to => 'response#saving'

  get 'question/select_questionnaire_type', :controller => "questionnaire", :action => 'select_questionnaire_type'
  get ':controller/service.wsdl', :action => 'wsdl'

  get ':controller(/:action(/:id))(.:format)'
  get 'password_edit/check_reset_url', controller: :password_retrieval, action: :check_reset_url
  match '*path' => 'content_pages#view', via: [:get, :post] unless Rails.env.development?
end
