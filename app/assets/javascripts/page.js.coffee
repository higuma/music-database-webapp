# class/instance common prefixes
NAMES = ['artist', 'release', 'track']

# classes / singleton instances by name
Models = {}         # model classes
Items = {}          # collection instances
ModelViews = {}     # Model view classes
ItemsViews = {}     # collection view (controller) instances
ItemsMenus = {}     # new/edit/delete dropdown menu view instances

# Model classes
MODEL_SPECS =
  artist:
    defaults:
      name: ''
    validate: (attrs) ->
      name = attrs.name
      return 'Artist name is empty.' if name == ''
      for item in Items['artist'].models
        if item != @ && item.get('name') == name
          return "Artist name \"#{name}\" already exists."
      return

  release:
    defaults:
      title: ''
      year: (new Date).getFullYear()
    validate: (attrs) ->
      return 'Release title is empty.' if attrs.title == ''

  track:
    defaults:
      number: undefined
      title: ''
      minutes: undefined
      seconds: undefined
    validate: (attrs) ->
      return 'Track title is empty.' if attrs.title == ''

for name, spec of MODEL_SPECS
  Models[name] = Backbone.Model.extend spec

# Collection instances
SubCollection = Backbone.Collection.extend
  setOwner: (owner) ->
    return false if @owner == owner
    if (@owner = owner)?
      @fetch()
    else
      @reset()
    true

compareString = do ->
  RE_PRE = /^(?:THE|A)\s/
  RE_W = /\s/g
  (a, b, attr) ->
    a = a.get(attr).toUpperCase().replace(RE_PRE, '').replace(RE_W, '')
    b = b.get(attr).toUpperCase().replace(RE_PRE, '').replace(RE_W, '')
    if a < b
      -1
    else if a > b
      1
    else
      0

compareNumberAndString = (a, b, attrNum, attrStr) ->
  x = a.get attrNum
  y = b.get attrNum
  if x < y
    -1
  else if x > y
    1
  else
    compareString a, b, attrStr

COLLECTION_SPECS =
  artist:
    inherits: Backbone.Collection
    url: '/api/artists'
    comparator: (a, b) -> compareString a, b, 'name'

  release:
    inherits: SubCollection
    url: -> "/api/artists/#{@owner.get('id')}/releases"
    comparator: (a, b) -> compareNumberAndString a, b, 'year', 'title'

  track:
    inherits: SubCollection
    url: -> "/api/artists/#{@owner.get('artist_id')}/releases/#{@owner.get('id')}/tracks"
    comparator: (a, b) -> compareNumberAndString a, b, 'number', 'title'

for name, spec of COLLECTION_SPECS
  Items[name] = new (spec.inherits.extend(_.extend spec, model: Models[name]))

# Model(singular) views (classes)
MODEL_VIEW_SPEC =
  tagName: 'li'
  className: 'width-max'

  render: -> @$el.html @template(@model.toJSON())

for name in NAMES
  ModelViews[name] = Backbone.View.extend _.extend MODEL_VIEW_SPEC,
    template: _.template $("#template-#{name}").html()

# Collection views (controllers)
CollectionView = Backbone.View.extend
  events:
    'click li': 'onSelectItem'

  initialize: (options) ->
    options.parentView.childView = @ if options.parentView?
    @listenTo @items, 'sync', @onSync
    @selected = null

  render: ->
    @$el.empty()
    for item in @items.models
      view = new @view model: item
      view.render()
      view.$el.attr 'item-id', item.id
      view.$el.addClass('active') if item == @item
      @$el.append view.$el
    @

  onSelectItem: (event) ->
    $('.active', @el).removeClass 'active'
    $target = $ event.currentTarget
    $target.addClass 'active'
    @item = @items.get Number($target.attr 'item-id')
    @syncChildView()

  onSync: ->
    if @items.length > 0
      @item = @items.models[0] unless @item
      ItemsMenus[@name].enable new: true, edit: true, delete: true
    else
      @item = null
      ItemsMenus[@name].enable new: @items.owner?, edit: false, delete: false
    @render()
    @syncChildView()

  syncChildView: ->
    @childView.syncFromParent @item if @childView?

  syncFromParent: (owner) ->
    if @items.setOwner(owner)
      @item = null
      @onSync() unless owner

  onCreate: (@item) ->

  onUpdate: (@item) ->
    @items.sort()

  onDelete: (index) ->
    length = @items.length
    if length > 0
      index = length - 1 if index >= length
      @item = @items.models[index]
    @onSync()

parentView = null
for name in NAMES
  klass = CollectionView.extend
    name: name
    el: "#list-#{name}"
    items: Items[name]
    view: ModelViews[name]
  parentView = ItemsViews[name] = new klass parentView: parentView

# Modal action views (instances)
ModalEdit = Backbone.View.extend
  template: _.template $('#template-validation-error').html()

  events:
    'click .btn-primary': 'apply'

  titleMessage:
    create: 'New'
    update: 'Edit'

  applyMessage:
    create: 'Create'
    update: 'Update'

  initialize: ->
    @controls = @controls() if $.type(@controls) == 'function'

  show: (@item) ->
    if @item?
      @mode = 'update'
      data = @item.attributes
    else
      @mode = 'create'
      data = @defaults
    @renderAlert()
    $('.modal-title', @el).html "#{@titleMessage[@mode]} #{@name}"
    $('.btn-primary', @el).html @applyMessage[@mode]
    for attr in @attributes
      @controls[attr].val data[attr]
    @$el.modal 'show'

  apply: (event) ->
    data = {}
    for attr in @attributes
      data[attr] = @controls[attr].val()
    switch @mode
      when 'create'
        item = Items[@name].create data, wait: true
        if item.validationError?
          @renderAlert item
          item.destroy()
          return
        ItemsViews[@name].onCreate item
      when 'update'
        return @renderAlert @item unless @item.save data
        ItemsViews[@name].onUpdate @item
    @$el.modal 'hide'

  renderAlert: (item) ->
    $('.alert-dismissible', @el).remove()
    $('.modal-body', @el).prepend @template(item) if item?

MODAL_EDIT_SPECS =
  artist:
    attributes: ['name']

    defaults:
      name: ''

    controls: ->
      name: $ 'input[name="name"]', @el

  release:
    attributes: ['title', 'year']

    defaults:
      title: ''
      year: (new Date).getFullYear()

    controls: ->
      title: $ 'input[name="title"]', @el
      year: $ 'select[name="year"]', @el

  track:
    attributes: ['number', 'title', 'minutes', 'seconds']

    defaults:
        number: 0
        title: ''
        minutes: 0
        seconds: 0

    controls: ->
      number: $ 'select[name="number"]', @el
      title: $ 'input[name="title"]', @el
      minutes: $ 'select[name="minutes"]', @el
      seconds: $ 'select[name="seconds"]', @el

ModalEditViews = {}     # new/edit modal view instances
for name, spec of MODAL_EDIT_SPECS
  spec = _.extend spec,
    el: "#modal-edit-#{name}"
    name: name
  ModalEditViews[name] = new (ModalEdit.extend spec)

NAME_ATTRS =
  artist: 'name'
  release: 'title'
  track: 'title'

ModalDeleteView = do -> # delete modal view instance
  klass = Backbone.View.extend
    el: '#modal-delete'

    events:
      'click .btn-primary': 'apply'

    show: (@name, @item) ->
      $('.modal-title', @el).html "Delete #{@name} - #{@item.get NAME_ATTRS[@name]}"
      $('.modal-body', @el).html "Are you sure?"
      @$el.modal 'show'

    apply: ->
      index = Items[@name].indexOf @item
      @item.destroy()
      ItemsViews[@name].onDelete index
      @$el.modal 'hide'

  new klass

# Menus
CollectionMenu = Backbone.View.extend
  events:
    'click li': 'onMenu'

  onMenu: (event) ->
    li = $ event.currentTarget
    return if li.hasClass 'disabled'
    switch li.attr 'action'
      when 'new' then ModalEditViews[@name].show()
      when 'edit' then ModalEditViews[@name].show @controller.item
      when 'delete' then ModalDeleteView.show @name, @controller.item

  enable: (actions) ->
    for action, ena of actions
      $("li[action='#{action}']", @el).toggleClass 'disabled', !ena

for name in NAMES
  klass = CollectionMenu.extend
    el: "#menu-#{name}"
    controller: ItemsViews[name]
    name: name
  ItemsMenus[name] = new klass

# start application
Items['artist'].fetch()
