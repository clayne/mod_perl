#include "mod_perl.h"

/*
 * pcw == Parsed Config Walker
 * generic functions for walking parsed config using callbacks
 */

void ap_pcw_walk_location_config(apr_pool_t *pconf, server_rec *s,
                                 core_server_config *sconf,
                                 module *modp,
                                 ap_pcw_dir_cb_t dir_cb, void *data)
{
    int i;
    ap_conf_vector_t **urls = (ap_conf_vector_t **)sconf->sec_url->elts;

    for (i = 0; i < sconf->sec_url->nelts; i++) {
        core_dir_config *conf =
            ap_get_module_config(urls[i], &core_module);
        void *dir_cfg = ap_get_module_config(urls[i], modp);     
     
        if (!dir_cb(pconf, s, dir_cfg, conf->d, data)) {
            break;
        }
    }
}

void ap_pcw_walk_directory_config(apr_pool_t *pconf, server_rec *s,
                                  core_server_config *sconf,
                                  module *modp,
                                  ap_pcw_dir_cb_t dir_cb, void *data)
{
    int i;
    ap_conf_vector_t **dirs = (ap_conf_vector_t **)sconf->sec_dir->elts;

    for (i = 0; i < sconf->sec_dir->nelts; i++) {
        core_dir_config *conf =
            ap_get_module_config(dirs[i], &core_module);
        void *dir_cfg = ap_get_module_config(dirs[i], modp);

        if (!dir_cb(pconf, s, dir_cfg, conf->d, data)) {
            break;
        }
    }
}

void ap_pcw_walk_files_config(apr_pool_t *pconf, server_rec *s,
                              core_dir_config *dconf,
                              module *modp,
                              ap_pcw_dir_cb_t dir_cb, void *data)
{
    int i;
    ap_conf_vector_t **dirs = (ap_conf_vector_t **)dconf->sec_file->elts;

    for (i = 0; i < dconf->sec_file->nelts; i++) {
        core_dir_config *conf =
            ap_get_module_config(dirs[i], &core_module);
        void *dir_cfg = ap_get_module_config(dirs[i], modp);

        if (!dir_cb(pconf, s, dir_cfg, conf->d, data)) {
            break;
        }
    }
}

void ap_pcw_walk_default_config(apr_pool_t *pconf, server_rec *s,
                                module *modp,
                                ap_pcw_dir_cb_t dir_cb, void *data)
{
    core_dir_config *conf = 
        ap_get_module_config(s->lookup_defaults, &core_module);
    void *dir_cfg = 
        ap_get_module_config(s->lookup_defaults, modp);

    dir_cb(pconf, s, dir_cfg, conf->d, data);
}

void ap_pcw_walk_server_config(apr_pool_t *pconf, server_rec *s,
                               module *modp,
                               ap_pcw_srv_cb_t srv_cb, void *data)
{
    void *cfg = ap_get_module_config(s->module_config, modp);

    if (!cfg) {
        return;
    }

    srv_cb(pconf, s, cfg, data);
}

void ap_pcw_walk_config(apr_pool_t *pconf, server_rec *s,
                        module *modp, void *data,
                        ap_pcw_dir_cb_t dir_cb, ap_pcw_srv_cb_t srv_cb)
{
    for (; s; s = s->next) {
        core_dir_config *dconf = 
            ap_get_module_config(s->lookup_defaults,
                                 &core_module);

        core_server_config *sconf =
            ap_get_module_config(s->module_config,
                                 &core_module);

        if (dir_cb) {
            ap_pcw_walk_location_config(pconf, s, sconf, modp, dir_cb, data);
            ap_pcw_walk_directory_config(pconf, s, sconf, modp, dir_cb, data);
            ap_pcw_walk_files_config(pconf, s, dconf, modp, dir_cb, data);
            ap_pcw_walk_default_config(pconf, s, modp, dir_cb, data);
        }

        if (srv_cb) {
            ap_pcw_walk_server_config(pconf, s, modp, srv_cb, data);
        }
    }
}
