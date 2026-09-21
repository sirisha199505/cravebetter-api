
class App::Routes < Roda
  include App::Router::AllPlugins

  plugin :not_found do
    { status: 'error', data: 'Not Found' }
  end

  plugin :error_handler do |e|
    App.logger.error("Unhandled error: #{e.message}")
    App.logger.error(e.backtrace.first(5).join("\n"))
    response['Content-Type'] = 'application/json'
    response.status = 500
    { status: 'error', data: e.message }.to_json
  end

  def do_crud(klass, r, only='CRUDL', opts = {})
    r.post { klass[r, opts].create } if only.include?('C')
    r.get(Integer) {|id| klass[r, opts.merge(id: id)].get} if only.include?('R')
    r.get { klass[r, opts].list } if only.include?('L')
    r.put(Integer) {|id| klass[r, opts.merge(id: id)].update } if only.include?('U')
    r.delete(Integer) {|id| klass[r, opts.merge(id: id)].delete } if only.include?('D')
  end

  route do |r|
    r.public

    r.root do
      File.read(File.join(App.root, 'public', 'index.html'))
    end

    r.on 'admin' do
      r.get do
        File.read(File.join(App.root, 'public', 'index.html'))
      end
    end

    r.on 'api' do
      r.response['Content-Type'] = 'application/json'

      # ── Public endpoints (no auth required) ──────────────────────

      r.post('login')    { Session[r].login }
      r.post('register') { Session[r].register }
      r.post('forgot-password') { Users[r].forgot_password }
      r.post('validate-password-token') { Users[r].validate_password_token }
      r.post('reset-password') { Users[r].reset_password }

      r.get 'version' do
        { status: 'success', version: 1 }
      end

      # Public: list products (optionally filtered by ?category=)
      r.on 'products' do
        r.get { Products[r].list }
        r.get(Integer) { |id| Products[r, id: id].get }
      end

      # Public: page contents (privacy policy, terms, etc.)
      r.on 'page-contents' do
        r.get(String) { |slug| PageContents[r, slug: slug].get_by_slug }
      end

      # Public: FAQs
      r.on 'faqs' do
        r.get { Faqs[r].list }
      end

      # Public: testimonials (?featured=true for the homepage strip)
      r.on 'testimonials' do
        r.get { Testimonials[r].list }
      end

      # Public: gallery — folder list first, then a folder's images
      # (?folder=<slug>&page=&page_size=), always paginated.
      r.on 'gallery' do
        r.get('folders') { GalleryFolders[r].list }
        r.get('links')   { GalleryLinks[r].list }
        r.get { GalleryItems[r].list }
      end

      # Public: Pincode lookup proxy (avoids browser CORS on postalpincode.in)
      r.on 'pincode' do
        r.get String do |pin|
          case (result = App::PincodeLookup.lookup(pin))
          when Hash
            { status: 'success', data: result }
          when App::PincodeLookup::NOT_FOUND
            { status: 'error', reason: 'not_found', data: 'Pincode not found' }
          else
            { status: 'error', reason: 'unavailable', data: 'Pincode lookup unavailable' }
          end
        end
      end

      # Public: place an order from the checkout page
      r.post('orders') { Orders[r].place }

      # Public: submit a bulk order request
      r.post('bulk-orders') { BulkOrders[r].create }

      # Public: Razorpay payment
      r.on 'payments' do
        r.post('create-order') { Payments[r].create_order }
        r.post('verify')       { Payments[r].verify }
      end

      # Public: Razorpay webhook (server-to-server, verified by signature)
      r.post('webhooks/razorpay') { Payments[r].webhook }

      # ── Authenticated routes ──────────────────────────────────────

      auth_required!

      r.on 'me' do
        r.get('info') { Users[r].info }
        r.put('update-password') { Users[r].update_password }
      end

      # ── Admin-only routes ─────────────────────────────────────────

      admin_required!

      begin
        r.on 'users' do
          do_crud(Users, r, 'CRUDL')
        end

        r.on 'admin' do
          r.on 'products' do
            do_crud(Products, r, 'CRUDL')
          end

          r.on 'orders' do
            r.get { Orders[r].list }
            r.get(Integer) { |id| Orders[r, id: id].get }
            r.put(Integer) { |id| Orders[r, id: id].update_status }
          end

          r.on 'customers' do
            r.get { Customers[r].list }
          end

          r.on 'bulk-orders' do
            r.get { BulkOrders[r].list }
            r.get(Integer) { |id| BulkOrders[r, id: id].get }
            r.put(Integer) { |id| BulkOrders[r, id: id].update_status }
          end

          r.on 'page-contents' do
            r.get(String)  { |slug| PageContents[r, slug: slug].get_by_slug }
            r.put(String)  { |slug| PageContents[r, slug: slug].upsert }
          end

          r.on 'faqs' do
            r.get    { Faqs[r].admin_list }
            r.post   { Faqs[r].create }
            r.put(Integer)    { |id| Faqs[r, id: id].update }
            r.delete(Integer) { |id| Faqs[r, id: id].delete }
          end

          r.on 'testimonials' do
            r.get    { Testimonials[r].admin_list }
            r.post   { Testimonials[r].create }
            r.put(Integer)    { |id| Testimonials[r, id: id].update }
            r.delete(Integer) { |id| Testimonials[r, id: id].delete }
          end

          r.on 'gallery' do
            # 'folders' and 'bulk' must be matched before the bare verbs below.
            r.on 'folders' do
              r.get    { GalleryFolders[r].admin_list }
              r.post   { GalleryFolders[r].create }
              r.put(Integer)    { |id| GalleryFolders[r, id: id].update }
              r.delete(Integer) { |id| GalleryFolders[r, id: id].delete }
            end
            r.on 'links' do
              r.get    { GalleryLinks[r].admin_list }
              r.post   { GalleryLinks[r].create }
              r.put(Integer)    { |id| GalleryLinks[r, id: id].update }
              r.delete(Integer) { |id| GalleryLinks[r, id: id].delete }
            end
            r.post('bulk') { GalleryItems[r].bulk_create }
            r.get    { GalleryItems[r].admin_list }
            r.post   { GalleryItems[r].create }
            r.put(Integer)    { |id| GalleryItems[r, id: id].update }
            r.delete(Integer) { |id| GalleryItems[r, id: id].delete }
          end

          # Presigned S3 PUT URLs for admin image uploads
          r.on 'uploads' do
            r.post('presign') { Uploads[r].presign }
          end
        end

      rescue => e
        App.logger.error("API Error: #{e.message}")
        App.logger.error(e.backtrace)
        { status: 'error', message: "An error occurred: #{e.message}" }
      end
    end

    # Fallback — serve the React SPA
    r.get do
      File.read(File.join(App.root, 'public', 'index.html'))
    end
  end

  before do
    @time = Time.now
    App::Helpers::Before.run!(request)
  end

  after do |res|
    rtype = request.request_method
    App.logger.info("→ [#{Time.now - @time} seconds] - [#{rtype}]#{request.path}")
  end

  def auth_required!
    unless App.cu.valid?
      request.halt(401, {'Content-Type' => 'application/json'},{ status: 'Unauthorized!' }.to_json)
    end
  end

  def admin_required!
    unless (App.cu.user_obj.admin? || App.cu.user_obj.rgm?)
      request.halt(403, {'Content-Type' => 'application/json'},{ status: 'Forbidden!' }.to_json)
    end
  end
end

App.require_blob('services/base.rb')
App.require_blob('services/*.rb')

App::Routes.send(:include, App::Services)
