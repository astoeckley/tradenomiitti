const json2csv = require('json2csv');

module.exports = function initialize(params) {
  const knex = params.knex;
  const util = params.util;
  const sebacon = params.sebacon;

  function report(req, res, next) {
    util.userForSession(req)
      .then(user => sebacon.isAdmin(user.remote_id))
      .then(isAdmin => {
        if (!isAdmin) return Promise.reject({ status: 403, msg: 'Non Admin tried to access report' });
        return null;
      })
      .then(() => {
        return knex('users')
          .where({})
          .select('users.remote_id')
          .select(knex.raw('users.data->>\'name\' as nickname'))
          .select(knex.raw('users.data->>\'profile_creation_consented\' as profile_created'))
          .select(knex.raw('(select count(*) from contacts where contacts.from_user = users.id) as sent_business_cards'))
          .select(knex.raw('(select count(*) from contacts where contacts.to_user = users.id) as received_business_cards'))
          .select(knex.raw('(select count(*) from ads where ads.user_id = users.id) as ads'))
          .select(knex.raw('(select count(*) from answers where answers.user_id = users.id) as answers'))
          .select(knex.raw('\
(select sum((select count(answers.*) from answers where answers.ad_id = ads.id)) / count(ads.*) from ads \
where ads.user_id = users.id\
) as gotten_answers_per_ad\
'));
      })
      .then(rows => json2csv({ data: rows, del: ';' }))
      .then(csv => {
        res.contentType('text/csv');
        res.send(csv);
      })
      .catch(next)
  }

  return {
    report
  };
};
