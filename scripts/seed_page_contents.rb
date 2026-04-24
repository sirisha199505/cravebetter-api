env_file = File.expand_path('../.env', __dir__)
if File.exist?(env_file)
  File.foreach(env_file) do |line|
    line.strip!
    next if line.empty? || line.start_with?('#')
    key, val = line.split('=', 2)
    val = val.to_s.strip.gsub(/\A["']|["']\z/, '')
    ENV[key.strip] ||= val
  end
end

require 'bundler'
Bundler.require(:default, :development)
require_relative '../src/app'

App.load!

PAGES = [
  {
    slug:    'privacy-policy',
    title:   'Privacy Policy',
    content: <<~HTML
      <p>At <strong>Crave Better Foods</strong>, we are committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our website <strong>cravebetter4u.com</strong> or place an order with us.</p>
      <p>By using our website, you agree to the collection and use of information in accordance with this policy.</p>

      <h2>1. Information We Collect</h2>
      <h3>Personal Information</h3>
      <p>When you place an order or register on our site, we may collect:</p>
      <ul>
        <li>Full name</li>
        <li>Email address</li>
        <li>Phone number</li>
        <li>Delivery address (city, state, PIN code)</li>
        <li>Order and payment details</li>
      </ul>

      <h3>Automatically Collected Information</h3>
      <p>When you visit our website, we may automatically collect certain information including your IP address, browser type, pages visited, and referring URLs. This helps us improve our website and user experience.</p>

      <h2>2. How We Use Your Information</h2>
      <p>We use the information we collect to:</p>
      <ul>
        <li>Process and fulfil your orders</li>
        <li>Send order confirmations and shipping updates</li>
        <li>Respond to customer service queries</li>
        <li>Send promotional emails (only if you have opted in)</li>
        <li>Improve our website, products, and services</li>
        <li>Comply with legal obligations</li>
      </ul>

      <h2>3. Sharing of Information</h2>
      <p>We do not sell, trade, or rent your personal information to third parties. We may share your information with:</p>
      <ul>
        <li><strong>Delivery partners</strong> — to fulfil your orders (name, address, phone number only)</li>
        <li><strong>Payment processors</strong> — to process transactions securely</li>
        <li><strong>Legal authorities</strong> — if required by law or to protect our rights</li>
      </ul>

      <h2>4. Cookies</h2>
      <p>Our website may use cookies to enhance your browsing experience. You can choose to disable cookies through your browser settings. Note that disabling cookies may affect the functionality of certain parts of the website.</p>

      <h2>5. Data Security</h2>
      <p>We implement appropriate technical and organisational measures to protect your personal data against unauthorised access, loss, or disclosure. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.</p>

      <h2>6. Data Retention</h2>
      <p>We retain your personal data for as long as necessary to fulfil the purposes outlined in this policy or as required by applicable law. Order records are typically retained for a minimum of 3 years.</p>

      <h2>7. Your Rights</h2>
      <p>You have the right to:</p>
      <ul>
        <li>Access the personal data we hold about you</li>
        <li>Request correction of inaccurate data</li>
        <li>Request deletion of your data (subject to legal obligations)</li>
        <li>Opt out of marketing communications at any time</li>
      </ul>
      <p>To exercise any of these rights, please contact us at <a href="mailto:listen@cravebetter4u.com">listen@cravebetter4u.com</a>.</p>

      <h2>8. Third-Party Links</h2>
      <p>Our website may contain links to third-party websites. We are not responsible for the privacy practices or content of those sites. We encourage you to review the privacy policies of any third-party websites you visit.</p>

      <h2>9. Changes to This Policy</h2>
      <p>We may update this Privacy Policy from time to time. Changes will be posted on this page with an updated revision date. We encourage you to review this page periodically.</p>

      <h2>10. Contact Us</h2>
      <p>If you have any questions or concerns about this Privacy Policy, please contact us at:</p>
      <ul>
        <li>Email: <a href="mailto:listen@cravebetter4u.com">listen@cravebetter4u.com</a></li>
        <li>Phone: +91 8008804992 / +91 8008804991 / +91 8008804997</li>
      </ul>
    HTML
  },

  {
    slug:    'terms-and-conditions',
    title:   'Terms & Conditions',
    content: <<~HTML
      <p>Welcome to <strong>Crave Better Foods</strong>. By accessing or using our website <strong>cravebetter4u.com</strong>, you agree to be bound by these Terms and Conditions. Please read them carefully before placing an order.</p>

      <h2>1. About Us</h2>
      <p>Crave Better Foods is an Indian food brand offering Ragi-based chocolate snack squares made with natural ingredients. Our products are manufactured and sold within India.</p>

      <h2>2. Use of the Website</h2>
      <p>You agree to use this website only for lawful purposes. You must not:</p>
      <ul>
        <li>Use the site in any way that violates applicable local, national, or international laws or regulations</li>
        <li>Transmit any unsolicited or unauthorised advertising material</li>
        <li>Attempt to gain unauthorised access to any part of the website</li>
        <li>Engage in any conduct that restricts or inhibits anyone's use of the website</li>
      </ul>

      <h2>3. Products</h2>
      <p>All products listed on our website are subject to availability. Product images are for illustrative purposes only; actual products may vary slightly. We reserve the right to discontinue any product at any time without prior notice.</p>
      <p>We make every effort to display accurate nutritional information, but this may vary slightly due to natural ingredient variations. Please refer to the actual product packaging for the most accurate information.</p>

      <h2>4. Pricing</h2>
      <p>All prices are listed in Indian Rupees (₹) and are inclusive of applicable taxes unless stated otherwise. We reserve the right to change prices without prior notice. The price applicable to your order is the price at the time of placing the order.</p>

      <h2>5. Orders & Payments</h2>
      <p>By placing an order, you confirm that all information provided is accurate and complete. We reserve the right to refuse or cancel orders at our discretion, including in cases of pricing errors or suspected fraud.</p>
      <p>Payments must be completed at the time of placing the order. We accept payments via the methods listed at checkout. All transactions are processed securely.</p>

      <h2>6. Intellectual Property</h2>
      <p>All content on this website — including text, graphics, logos, images, and software — is the property of Crave Better Foods and is protected by applicable intellectual property laws. You may not reproduce, distribute, or use any content without our prior written consent.</p>

      <h2>7. Limitation of Liability</h2>
      <p>Crave Better Foods shall not be liable for any indirect, incidental, or consequential damages arising out of your use of the website or our products, to the fullest extent permitted by law.</p>

      <h2>8. Governing Law</h2>
      <p>These Terms and Conditions shall be governed by and construed in accordance with the laws of India. Any disputes arising shall be subject to the exclusive jurisdiction of the courts in Hyderabad, Telangana.</p>

      <h2>9. Changes to Terms</h2>
      <p>We reserve the right to update these Terms and Conditions at any time. Continued use of the website after changes are posted constitutes your acceptance of the revised terms.</p>

      <h2>10. Contact</h2>
      <p>For any questions regarding these Terms, please contact us at <a href="mailto:listen@cravebetter4u.com">listen@cravebetter4u.com</a>.</p>
    HTML
  },

  {
    slug:    'cancellation-refund-policy',
    title:   'Cancellation & Refund Policy',
    content: <<~HTML
      <p>At <strong>Crave Better Foods</strong>, we take great pride in the quality of our products. We want you to be completely satisfied with every purchase. Please read our Cancellation and Refund Policy carefully.</p>

      <h2>1. Order Cancellation</h2>
      <h3>Before Dispatch</h3>
      <p>Orders can be cancelled within <strong>12 hours of placing the order</strong>, provided the order has not yet been dispatched. To request a cancellation, contact us immediately at <a href="mailto:listen@cravebetter4u.com">listen@cravebetter4u.com</a> or call us at +91 8008804992.</p>

      <h3>After Dispatch</h3>
      <p>Once an order has been dispatched, it cannot be cancelled. You may, however, raise a return or refund request as described below upon delivery.</p>

      <h2>2. Return Policy</h2>
      <p>We accept returns only in the following circumstances:</p>
      <ul>
        <li>The product received is <strong>damaged</strong> or <strong>defective</strong></li>
        <li>The product received is <strong>different from what was ordered</strong></li>
        <li>The product is <strong>past its expiry date</strong> at the time of delivery</li>
      </ul>
      <p><strong>Returns are not accepted for:</strong></p>
      <ul>
        <li>Change of mind or taste preference</li>
        <li>Products that have been opened or partially consumed</li>
        <li>Products damaged due to improper storage by the customer</li>
      </ul>

      <h2>3. How to Raise a Return Request</h2>
      <ol>
        <li>Contact us within <strong>48 hours of delivery</strong> at <a href="mailto:listen@cravebetter4u.com">listen@cravebetter4u.com</a></li>
        <li>Include your order number, a clear description of the issue, and photos of the damaged/incorrect product</li>
        <li>Our team will review your request and respond within 2 business days</li>
        <li>If approved, we will arrange a pickup or provide instructions for returning the product</li>
      </ol>

      <h2>4. Refund Process</h2>
      <p>Once your return is received and inspected, we will notify you of the approval or rejection of your refund. If approved:</p>
      <ul>
        <li><strong>Online payments:</strong> Refund will be credited to the original payment method within <strong>5–7 business days</strong></li>
        <li><strong>Cash on Delivery orders:</strong> Refund will be processed via bank transfer or UPI within <strong>5–7 business days</strong></li>
      </ul>
      <p>Shipping charges are non-refundable unless the return is due to our error.</p>

      <h2>5. Replacement</h2>
      <p>In certain cases, instead of a refund, we may offer a <strong>replacement</strong> of the same product at no additional cost. This will be discussed and agreed upon with you during the return process.</p>

      <h2>6. Bulk Orders</h2>
      <p>Cancellation and refund policies for bulk orders may differ. Please refer to the terms agreed upon at the time of your bulk order placement, or contact us for clarification.</p>

      <h2>7. Contact Us</h2>
      <p>For all cancellation and refund enquiries, please reach out to us:</p>
      <ul>
        <li>Email: <a href="mailto:listen@cravebetter4u.com">listen@cravebetter4u.com</a></li>
        <li>Phone: +91 8008804992 / +91 8008804991 / +91 8008804997</li>
      </ul>
    HTML
  },

  {
    slug:    'shipping-policy',
    title:   'Shipping Policy',
    content: <<~HTML
      <p>Thank you for shopping with <strong>Crave Better Foods</strong>. We are committed to delivering your favourite snacks fresh and on time. Please read our Shipping Policy below.</p>

      <h2>1. Shipping Coverage</h2>
      <p>We currently ship across <strong>India</strong>. We are unable to process international orders at this time.</p>

      <h2>2. Shipping Charges</h2>
      <ul>
        <li><strong>Free delivery</strong> on all orders above <strong>₹599</strong></li>
        <li>For orders below ₹599, a flat shipping fee will be applied at checkout</li>
      </ul>

      <h2>3. Processing Time</h2>
      <p>All orders are processed within <strong>1–2 business days</strong> of payment confirmation. Orders placed on weekends or public holidays will be processed on the next working day.</p>

      <h2>4. Estimated Delivery Time</h2>
      <ul>
        <li><strong>Metro cities</strong> (Hyderabad, Bengaluru, Mumbai, Delhi, Chennai, Kolkata): 2–4 business days</li>
        <li><strong>Tier 2 & Tier 3 cities:</strong> 4–7 business days</li>
        <li><strong>Remote areas:</strong> 7–10 business days</li>
      </ul>
      <p>Delivery timelines are estimates and may vary due to unforeseen circumstances such as courier delays, natural events, or public holidays.</p>

      <h2>5. Order Tracking</h2>
      <p>Once your order is dispatched, you will receive a confirmation email or SMS with your tracking details. You can use the tracking number to monitor your shipment on our courier partner's website.</p>

      <h2>6. Packaging</h2>
      <p>We take product freshness seriously. All orders are packed in food-grade, tamper-evident packaging to ensure your Crave Better squares reach you in perfect condition.</p>

      <h2>7. Undelivered or Returned Shipments</h2>
      <p>If a delivery attempt fails due to an incorrect address or unavailability of the recipient:</p>
      <ul>
        <li>The courier will attempt delivery a maximum of <strong>2 times</strong></li>
        <li>If the shipment is returned to us, we will contact you to reattempt delivery (re-shipping charges may apply)</li>
        <li>Please ensure the shipping address and contact number provided are accurate at the time of ordering</li>
      </ul>

      <h2>8. Damaged in Transit</h2>
      <p>If your order arrives damaged, please take photographs and contact us within <strong>48 hours of delivery</strong> at <a href="mailto:listen@cravebetter4u.com">listen@cravebetter4u.com</a>. We will arrange a replacement or refund as per our Refund Policy.</p>

      <h2>9. Bulk Orders</h2>
      <p>Shipping timelines and charges for bulk orders may differ based on quantity and location. Our team will provide specific delivery details at the time of confirming your bulk order.</p>

      <h2>10. Contact Us</h2>
      <p>For any shipping-related queries, please reach us at:</p>
      <ul>
        <li>Email: <a href="mailto:listen@cravebetter4u.com">listen@cravebetter4u.com</a></li>
        <li>Phone: +91 8008804992 / +91 8008804991 / +91 8008804997</li>
      </ul>
    HTML
  },

  {
    slug:    'contact-us',
    title:   'Contact Us',
    content: <<~HTML
      <p>We'd love to hear from you — whether you have a question about our products, need help with an order, or just want to say hello. Our team is here to help.</p>

      <h2>Get in Touch</h2>
      <ul>
        <li><strong>Email:</strong> <a href="mailto:listen@cravebetter4u.com">listen@cravebetter4u.com</a></li>
        <li><strong>Phone:</strong> +91 8008804992 / +91 8008804991 / +91 8008804997</li>
      </ul>
      <p>We typically respond to all enquiries within <strong>24–48 business hours</strong> (Monday to Saturday, 10 AM – 6 PM IST).</p>

      <h2>For Bulk Orders</h2>
      <p>If you're interested in ordering in bulk for your office, school, events, or gifting — we'd love to discuss a custom arrangement. Please use our <a href="/bulk-orders">Bulk Orders form</a> for a quicker response, or email us directly with your requirements.</p>

      <h2>For Order Issues</h2>
      <p>If you have a concern about a delivered order (damaged product, wrong item, missing items), please email us at <a href="mailto:listen@cravebetter4u.com">listen@cravebetter4u.com</a> with your order number and photographs. We'll get it sorted for you.</p>

      <h2>Feedback & Suggestions</h2>
      <p>We're always looking to improve. If you have feedback about our products, website, or service, we genuinely want to hear it. Drop us a note at <a href="mailto:listen@cravebetter4u.com">listen@cravebetter4u.com</a> — every message is read by our team.</p>
    HTML
  },
]

puts "Seeding page contents..."

PAGES.each do |page|
  existing = App::Models::PageContent.first(slug: page[:slug])
  if existing
    existing.update(page.merge(updated_at: Time.now))
    puts "  Updated: #{page[:slug]}"
  else
    App::Models::PageContent.create(page.merge(created_at: Time.now, updated_at: Time.now))
    puts "  Created: #{page[:slug]}"
  end
end

puts "Done. #{App::Models::PageContent.count} page(s) seeded."
