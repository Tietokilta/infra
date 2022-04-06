# Tietokilta/infra

[Architecture diagram](https://miro.com/app/board/o9J_lVeCVWw=/)

## Development

**NEVER RUN `terraform apply` LOCALLY, WE HAVE A WORKFLOW FOR THAT.**

Initialize terraform by running:
```shell
az login
terraform init
terraform workspace select prod
```

Run `terraform plan` to see changes. Run `terraform fmt` before committing to avoid linter errors.

`terraform plan` will prompt for the input variables. If you often work locally, you may want to set up an env file
for this (ask the Master of Digitalization for one); you can also just provide random values, ignore the irrelevant
changes locally, and verify the final plan after making a pull request.

**NEVER RUN `terraform apply` LOCALLY, WE HAVE A WORKFLOW FOR THAT.**

## Fixing collisions (importing resources)

Sometimes you get yourself in a situation where Terraform tries to create an already-existing resource (see below
for examples). You have two options:

- Delete the Azure resource(s) and re-run the deployment (if it's something lightweight and won't reappear too early).
- Import the Azure resource(s) to Terraform state.

To import Azure resources, run:

```shell
terraform import module.<foo>.<bar> /subscriptions/<subscription-id>/<path>
```

Typically the item address, starting `module.`, and the resource path, starting `/subscriptions`, are printed to
the console very close to the deployment error. You can get our subscription ID from `az account show` as `"id"`.

This will also prompt for all the relevant secrets, but you can often just provide something random and it'll
import just fine (or at least fix itself on the next deploy). If some secret is used by the imported resource, you
might need to provide the real value.

## Known issues

- At least when changing CNAME'd CDN endpoints, and possibly other CNAME'd resources, Azure can cause issues.
  - Firstly, you need to remove the CNAME to delete the existing resource and then re-create the CNAME before
    re-creating the resource. This does **not** play well with the fact that you sometimes need to re-create CDN
    endpoints. If this starts causing repeated issues, we'll apply the workaround from
    [the relevant azurerm backend issue](https://github.com/hashicorp/terraform-provider-azurerm/issues/11231), but
    otherwise we'll keep it as-is to avoid subdomain takeovers.
  - As a bonus, disabling and re-enabling TLS on a CDN custom domain takes 8 hours, during which re-creation fails.
    The cloud is clearly the future :~)
- Azure is "user-friendly" and does stuff like creating a `$web` container when you enable static website serving on
  a storage account. However, this causes a collision if we also define said container in Terraform. This requires
  importing or deleting resources (see above).
- With Azure, failed applies often result in the resources being created anyway, which again forces you to then
  manually fix collisions.
