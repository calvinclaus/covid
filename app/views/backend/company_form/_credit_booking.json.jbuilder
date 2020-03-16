json.(credit_booking, :id, :name, :booking_date, :credit_amount, :errors)
if credit_booking.frontend_id.present?
  json.frontend_id credit_booking.frontend_id
else
  json.frontend_id credit_booking.id
end
