class UiJobWizardController < ApplicationController
  include FiltersHelper
  def categories
    job_categories = resource_scope
                     .search_for("job_category ~ \"#{params[:search]}\"")
                     .select(:job_category).distinct
                     .reorder(:job_category)
                     .pluck(:job_category)
    render :json => {:job_categories => job_categories, :with_katello => with_katello, default_category: default_category, default_template: default_template&.id}
  end

  def template
    job_template = JobTemplate.authorized.find(params[:id])
    advanced_template_inputs, template_inputs = map_template_inputs(job_template.template_inputs_with_foreign).partition { |x| x["advanced"] }
    render :json => {
      :job_template => job_template,
      :effective_user => job_template.effective_user,
      :template_inputs => template_inputs,
      :advanced_template_inputs => advanced_template_inputs,
    }
  end

  def map_template_inputs(template_inputs_with_foreign)
    template_inputs_with_foreign.map { |input| input.attributes.merge({:resource_type_tableize => input.resource_type&.tableize }) }
  end

  def default_category
    default_template&.job_category
  end

  def default_template
    if (setting_value = Setting['remote_execution_form_job_template'])
      JobTemplate.authorized(:view_job_templates).find_by :name => setting_value
    end
  end

  def resource_name(nested_resource = nil)
    nested_resource || 'job_template'
  end

  def with_katello
    !!defined?(::Katello)
  end

  def resource_class
    JobTemplate
  end

  def action_permission
    :view_job_templates
  end

  def resources
    resource_type = params[:resource]
    resource_list = resource_type.constantize.authorized("view_#{resource_type.underscore.pluralize}").all.map { |r| {:name => r.to_s, :id => r.id } }.select { |v| v[:name] =~ /#{params[:name]}/ }
    render :json => { :results =>
      resource_list.sort_by { |r| r[:name] }.take(100), :subtotal => resource_list.count}
  end
end
