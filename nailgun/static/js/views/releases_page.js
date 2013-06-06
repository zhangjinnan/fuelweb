define(
[
    'views/common',
    'views/dialogs',
    'text!templates/release/list.html'
],
function(commonViews, dialogViews, releaseListTemplate) {
    'use strict';

    var ReleasesPage = commonViews.Page.extend({
        navbarActiveElement: 'releases',
        breadcrumbsPath: [['Home', '#'], 'OpenStack Releases'],
        title: 'OpenStack Releases',
        template: _.template(releaseListTemplate),
        'events': {
            'click .rhel-license': 'showAccountSettings'
        },
        showAccountSettings: function() {
            var dialog = dialogViews.RhelLicenseDialog();
            this.registerSubView(dialog);
            dialog.render();
        },
        initialize: function() {
            this.collection.on('sync', this.render, this);
        },
        render: function() {
            this.$el.html(this.template({releases: this.collection}));
            return this;
        }
    });

    return ReleasesPage;
});
