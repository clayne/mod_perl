/* Copyright 2001-2004 The Apache Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef MODPERL_ERROR_H
#define MODPERL_ERROR_H

/* to check whether $@ is set by ModPerl::Util::exit */
#define MODPERL_RC_EXIT APR_OS_START_USERERR + 0

char *modperl_error_strerror(pTHX_ apr_status_t rc);
        
void modperl_croak(pTHX_ apr_status_t rc, const char* func);

#define MP_RUN_CROAK(rc_run, func) STMT_START                \
    {                                                        \
        apr_status_t rc = rc_run;                            \
        if (rc != APR_SUCCESS) {                             \
            modperl_croak(aTHX_ rc, func);                   \
        }                                                    \
    } STMT_END

#endif /* MODPERL_ERROR_H */
