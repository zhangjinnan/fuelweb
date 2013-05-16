define([
    'chaplin',
    'models'
], function(Chaplin, models) {
    'use strict';

    var ClustersController = Chaplin.Controller.extend({
        show: function(params) {
            console.log('clusters', params);
            //this.navigate('#clusters', {replace: true});
            var clusters = this.collection = new models.Clusters();
            var nodes = new models.Nodes();
            var tasks = new models.Tasks();
            $.when(clusters.fetch(), nodes.fetch(), tasks.fetch()).done(_.bind(function() {
                clusters.each(function(cluster) {
                    cluster.set('nodes', new models.Nodes(nodes.where({cluster: cluster.id})));
                    cluster.set('tasks', new models.Tasks(tasks.where({cluster: cluster.id})));
                }, this);
                //this.setPage(ClustersPage, {collection: clusters});
            }, this));
            //this.view = new HelloWorldView({model: this.model});
        }
    });

    return ClustersController;
});
