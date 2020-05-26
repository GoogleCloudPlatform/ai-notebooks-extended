/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_dataproc_autoscaling_policy" "policy_a" {
  provider = google-beta
  project   = var.project_id
  policy_id = "policy-a"

  worker_config {
    min_instances = 2
    max_instances = 100
  }
  
  secondary_worker_config {
    min_instances = 2
    max_instances = 100
  }
    
  basic_algorithm {
    cooldown_period = "240s"
    yarn_config {
      scale_up_factor                = 0.05
      scale_down_factor              = 1
      scale_up_min_worker_fraction   = 0.0
      scale_down_min_worker_fraction = 0.0
      graceful_decommission_timeout  = "3600s"
    }
  }
}