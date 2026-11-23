# Company pages list and search every contact of the account (by phone too), so freelancers don't get them.
module Custom::CompanyPolicy
  %i[index? search? show? create? update?].each do |action|
    define_method(action) { !user.try(:crm_freelancer?) && super() }
  end
end
