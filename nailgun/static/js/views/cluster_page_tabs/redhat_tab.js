define(
[
    'models',
    'views/common',
    'views/dialogs',
    'text!templates/cluster/redhat_tab.html'
],
function(models, commonViews, dialogViews, redhatTabTemplate) {
    'use strict';

    var RedHatTab = commonViews.Tab.extend({
        template: _.template(redhatTabTemplate),
        events: {
        },
        initialize: function(options) {
            _.defaults(this, options);
        },
        render: function() {
            this.$el.html(this.template({cluster: this.model}));
            return this;
        }
    });

    return RedHatTab;
});
