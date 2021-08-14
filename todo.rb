require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def list_complete?(list)
    list[:todos].size > 0 && list[:todos].all? { |todo| todo[:completed] }
  end

  def count_completed(list)
    list[:todos].count { |todo| todo[:completed] }
  end

  def sort_lists_by_completed(lists)
    lists.sort_by { |list| list_complete?(list) ? 1 : 0 }
  end

  def sort_todos_by_completed(todos)
    todos.sort_by { |todo| todo[:completed] ? 1 : 0 }
  end

  def find_original_index(original_array, name)
    original_array.index { |element| element[:name] == name }
  end

  # def sort_lists(lists, &block)
  #   incomplete_lists = {}
  #   complete_lists = {}

  #   lists.each_with_index do |list, index|
  #     if list_complete?(list)
  #       complete_lists[list] = index
  #     else
  #       incomplete_lists[list] = index
  #     end
  #   end

  #   # incomplete_lists.each( { |id, list| yield list, id})
  #   # complete_lists.each { |id, list| yield list, id}

  #   incomplete_lists.each(&block)
  #   complete_lists.each(&block)
  # end

  # def sort_lists(lists, &block)
  #   complete_lists, incomplete_lists = list.partition { |list| list_complete?(list) }

  #   incomplete_lists.each { |list| yield list, lists.index(list) }
  #   complete_lists.each { |list| yield list, lists.index(list) }
  # end

  # def sort_todos(todos, &block)
  #   incomplete_todos = {}
  #   complete_todos = {}

  #   todos.each_with_index do |todo, index|
  #     if todo[:completed]
  #       complete_todos[todo] = index
  #     else
  #       incomplete_todos[todo] = index
  #     end
  #   end

  #   # incomplete_todos.each( { |id, todo| yield todo, id})
  #   # complete_todos.each { |id, todo| yield todo, id}

  #   incomplete_todos.each(&block)
  #   complete_todos.each(&block)
  # end


end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

def error_for_new_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: [] }
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end

post "/lists/:number/destroy" do
  number = params[:number].to_i
  session[:lists].delete_at(number)
  session[:success] = "The list has been deleted"
  redirect "/lists"
end

post "/lists/:number/todos" do
  @number = params[:number].to_i
  @list = session[:lists][@number]
  text = params[:todo].strip

  error = error_for_new_list_name(text)
  if error
    session[:error] = error
    erb :todos, layout: :layout
  else
    @list[:todos] << {name: text, completed: false}
    session[:success] = "The todo has been added"
    redirect "/lists/#{@number}"
  end
end

post "/lists/:number/todos/:todo_id/destroy" do
  @number = params[:number].to_i
  @list = session[:lists][@number]
  todo_id = params[:todo_id].to_i

  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted"
  redirect "/lists/#{@number}"
end

post "/lists/:number/todos/:todo_id" do
  @number = params[:number].to_i
  @list = session[:lists][@number]
  todo_id = params[:todo_id].to_i

  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo has been updated"

  redirect "/lists/#{@number}"
end

# post "/lists/:number/todos/:todo_id" do
#   @number = params[:number].to_i
#   @list = session[:lists][@number]
#   todo_id = params[:todo_id].to_i
#   completed = !@list[:todos][todo_id][:completed]
#   name = @list[:todos][todo_id][:name]

#   @list[:todos].delete_at(todo_id)

#   if completed
#     @list[:todos] << {name: name, completed: completed}
#   else
#     @list[:todos].unshift({name: name, completed: completed})
#   end


#   redirect "/lists/#{@number}"
# end

post "/lists/:number/complete_all" do
  @number = params[:number]
  @list = session[:lists][@number.to_i]

  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All todos have been completed"
  redirect "/lists/#{@number}"
end

get "/lists/:number/edit" do
  @number = params[:number]
  @list = session[:lists][@number.to_i]
  erb :edit_list, layout: :layout
end

get "/lists/:number" do
  @number = params[:number].to_i
  @list = session[:lists][@number]
  erb :todos, layout: :layout
end

post "/lists/:number" do
  list_name = params[:list_name].strip
  @number = params[:number].to_i
  @list = session[:lists][@number]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been renamed"
    redirect "/lists/#{@number}"
  end
end


