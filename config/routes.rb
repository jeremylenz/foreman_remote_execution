Rails.application.routes.draw do
  resources :job_templates, :except => [:show] do
    member do
      get 'clone_template'
      get 'lock'
      get 'export'
      get 'unlock'
      post 'preview'
    end
    collection do
      post 'preview'
      post 'import'
      get 'revision'
      get 'auto_complete_search'
      get 'auto_complete_job_category'
    end
  end

  match 'job_invocations/new', to: 'job_invocations#new', via: [:get, :post], as: 'new_job_invocation'
  resources :job_invocations, :only => [:create, :show, :index] do
    collection do
      post 'refresh'
      get 'chart'
      get 'preview_hosts'
      get 'auto_complete_search'
    end
    member do
      get 'rerun'
      post 'cancel'
    end
  end

  resources :remote_execution_features, :only => [:show, :index, :update]

  # index is needed so the auto_complete_search can be constructed, otherwise autocompletion in filter does not work
  resources :template_invocations, :only => [:show, :index] do
    collection do
      get 'auto_complete_search'
    end
  end

  constraints(:id => %r{[^/]+}) do
    get 'cockpit/host_ssh_params/:id', to: 'cockpit#host_ssh_params'
  end
  get 'cockpit/redirect', to: 'cockpit#redirect'
  get 'ui_job_wizard/categories', to: 'ui_job_wizard#categories'
  get 'ui_job_wizard/template/:id', to: 'ui_job_wizard#template'
  get 'ui_job_wizard/resources', to: 'ui_job_wizard#resources'

  match '/experimental/job_wizard', to: 'react#index', :via => [:get]

  namespace :api, :defaults => {:format => 'json'} do
    scope '(:apiv)', :module => :v2, :defaults => {:apiv => 'v2'}, :apiv => /v1|v2/, :constraints => ApiConstraints.new(:version => 2, :default => true) do
      resources :job_invocations, :except => [:new, :edit, :update, :destroy] do
        resources :hosts, :only => :none do
          get '/', :to => 'job_invocations#output'
          get '/raw', :to => 'job_invocations#raw_output'
        end
        member do
          post 'cancel'
          post 'rerun'
          get  'template_invocations', :to => 'template_invocations#template_invocations'
          get 'outputs'
          post 'outputs'
        end
      end

      resources :job_templates, :except => [:new, :edit] do
        resources :locations, :only => [:index, :show]
        resources :organizations, :only => [:index, :show]
        get :export, :on => :member
        post :clone, :on => :member
        collection do
          get 'revision'
          post 'import'
        end
      end

      resources :organizations, :only => [:index] do
        resources :job_templates, :only => [:index, :show]
      end

      resources :locations, :only => [:index] do
        resources :job_templates, :only => [:index, :show]
      end

      resources :templates, :only => :none do
        resources :foreign_input_sets, :only => [:index, :show, :create, :destroy, :update]
      end

      resources :remote_execution_features, :only => [:show, :index, :update]
    end
  end
end
