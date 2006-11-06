/* Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef MODPERL_APACHE_COMPAT_H
#define MODPERL_APACHE_COMPAT_H

/* back compat adjustements for older Apache versions */

#if !APR_HAS_THREADS
typedef unsigned long apr_os_thread_t;
typedef void * apr_thread_mutex_t;
#endif

/* back compat adjustements for older Apache versions
 * BACK_COMPAT_MARKER: make back compat issues easy to find :)
 */

/* use the following format:
 *     #if ! AP_MODULE_MAGIC_AT_LEAST(20020903,4)
 *         [compat code]
 *     #endif
 * and don't forget to insert comments explaining exactly
 * which httpd release allows us to remove the compat code
 */

/* ap_http_scheme is called ap_http_method in httpd 2.0 */
#ifndef ap_http_scheme
#define ap_http_scheme(r) ap_http_method(r)
#endif

#if AP_SERVER_MAJORVERSION_NUMBER>2 || AP_SERVER_MINORVERSION_NUMBER>=2
#define MP_HTTPD_HAS_OVERRIDE_OPTS
#endif

#define MP_HTTPD_OVERRIDE_HTACCESS (OR_LIMIT|OR_OPTIONS|OR_FILEINFO|OR_AUTHCFG|OR_INDEXES)

#define MP_HTTPD_OVERRIDE_OPTS_UNSET (-1)
#define MP_HTTPD_OVERRIDE_OPTS_DEFAULT (OPT_UNSET | \
                                        OPT_ALL | \
                                        OPT_INCNOEXEC | \
                                        OPT_SYM_OWNER | \
                                        OPT_MULTI)

#endif /* MODPERL_APACHE_COMPAT_H */
