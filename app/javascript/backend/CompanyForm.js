import React from "react";
import { Form, Button, Dropdown, Grid, Segment, Icon, Message, Header, Progress, Loader, } from 'semantic-ui-react';
import { setDefaultLocale, registerLocale } from "react-datepicker";
import CampaignPreview from "../shared/CampaignPreview.js";
import ScriptType from "../shared/ScriptType.js";
import DatePicker from "react-datepicker";
import axios from "axios";
import SwitchPercentageAbsolute from "../frontend/SwitchPercentageAbsolute.js"
import _ from "underscore"
const uuidv1 = require('uuid/v1');


export default class CompanyForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      ...props.initialFormData,
    }
    this.handleCampaignsChange = this.handleCampaignsChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleSearchesChange = this.handleSearchesChange.bind(this);
    this.handleBlacklistImportsChange = this.handleBlacklistImportsChange.bind(this);
    this.handleCreditBookingsChange = this.handleCreditBookingsChange.bind(this);
    this.handleProspectPoolsChange = this.handleProspectPoolsChange.bind(this);
    this.getStatiContinuously();
  }

  handleSearchesChange(searches) {
    this.setState({
      company: {
        ...this.state.company,
        searches,
      },
    })
  }


  handleCampaignsChange(campaigns, callback) {
    this.setState({
      company: {
        ...this.state.company,
        campaigns,
      },
    }, callback)
  }

  handleBlacklistImportsChange(blacklistImports) {
    this.setState({
      company: {
        ...this.state.company,
        blacklistImports,
      }
    })
  }

  handleCreditBookingsChange(creditBookings) {
    this.setState({
      company: {
        ...this.state.company,
        creditBookings,
      }
    })
  }

  handleProspectPoolsChange(prospectPools) {
    this.setState({
      company: {
        ...this.state.company,
        prospectPools,
      }
    })
  }

  handleLinkedInAccountsChange(accounts) {
    this.setState({
      linkedInAccounts: [
        ...accounts,
      ]
    })
  }

  getStatiContinuously(callback) {
    // TODO fix stoping of interval when component unmounted
    axios.get(this.state.company.showUrl)
      .then(({ data }) => {
        this.setState({
          company: {
            ...this.state.company,
            numProspects: data.company.numProspects,
            numProspectsWithoutSearch: data.company.numProspectsWithoutSearch,
            prospectDistributionStatus: data.company.prospectDistributionStatus,
            searches: this.state.company.searches.map(origSearch => {
              let updatedSearch = data.company.searches.find(newS => newS.id === origSearch.id);
              if (!present(updatedSearch)) return origSearch;
              return {
                ...origSearch,
                queries: updatedSearch.queries,
                status: updatedSearch.status,
                numProspects: updatedSearch.numProspects,
                numContactedProspects: updatedSearch.numContactedProspects,
                numBlacklistedProspects: updatedSearch.numBlacklistedProspects,
                numLeftProspects: updatedSearch.numLeftProspects,
                numConnectionErrors: updatedSearch.numConnectionErrors,
                numConnectionErrorsAfterDeadlineWhereErrorsCount: updatedSearch.numConnectionErrorsAfterDeadlineWhereErrorsCount,
              };
            }),
            campaigns: this.state.company.campaigns.map(origCampaign => {
              let updatedCampaign = data.company.campaigns.find(newC => newC.id === origCampaign.id);
              if (!present(updatedCampaign)) return origCampaign;
              return {
                ...origCampaign,
                numProspects: updatedCampaign.numProspects,
                numAssignedNotContactedProspects: updatedCampaign.numAssignedNotContactedProspects,
                numBlacklisted: updatedCampaign.numBlacklisted,
                numGenderUnknown: updatedCampaign.numGenderUnknown,
                numDelivered: updatedCampaign.numDelivered,
                numAccepted: updatedCampaign.numAccepted,
                numAnswered: updatedCampaign.numAnswered,
                numRepliedAfterStage: updatedCampaign.numRepliedAfterStage,
                numConnectionErrors: updatedCampaign.numConnectionErrors,
                numConnectionErrorsAfterDeadlineWhereErrorsCount: updatedCampaign.numConnectionErrorsAfterDeadlineWhereErrorsCount,
                numNotContactedAndBlacklisted: updatedCampaign.numNotContactedAndBlacklisted,
              };
            }),
            blacklistImports: this.state.company.blacklistImports.map(origImport => {
              let updatedImport = data.company.blacklistImports.find(newI => newI.id === origImport.id);
              if (!present(updatedImport)) return origImport;
              return {
                ...origImport,
                numBlacklisted: updatedImport.numBlacklisted,
                status: updatedImport.status,
              };
            }),
          }
        });
      })
      .catch(e => {
        console.log("getting status failed with error", e);
      })
      .finally(() => {
        setTimeout(this.getStatiContinuously.bind(this), 3000);
      })
  }

  handleSubmit() {
    this.setState({ saveErrorMessage: false, saveSuccess: false, loading: true, })
    axios.post(this.state.company.patchUrl, { compute: true, ...this.selectDataToSubmit(this.state) })
      .then(({ data } ) => {
        data.company.campaigns = data.company.campaigns.map(newC => {
          let oldCampaign = this.state.company.campaigns.find(oldC => oldC.frontendId === newC.frontendId);
          return {
            ...newC,
            openForEditing: oldCampaign.openForEditing,
          }
        });

        let newLinkedInAccounts = [...this.state.linkedInAccounts];
        let hasLinkedInAccountErrors = false;
        data.linkedInAccounts.forEach(updatedOrNew => {
          let foundIndex = newLinkedInAccounts.findIndex(a => a.frontendId === updatedOrNew.frontendId)
          if (present(updatedOrNew.errors)) {
            hasLinkedInAccountErrors = true;
          }
          if (foundIndex == -1) {
            newLinkedInAccounts.push({...updatedOrNew});
          } else {
            newLinkedInAccounts[foundIndex] = {...updatedOrNew, frontendId: present(updatedOrNew.id) ? updatedOrNew.id : updatedOrNew.frontendId};
          }
        });
        delete data.linkedInAccounts;

        data.company.searches = _.sortBy(data.company.searches, s => s.id || s.updatedAt)

        this.setState({
          ...data,
          linkedInAccounts: newLinkedInAccounts,
          saveSuccess: !present(data.company.errors) && !hasLinkedInAccountErrors,
          hasLinkedInAccountErrors,
          loading: false,
        })
        setTimeout(() => {
          this.setState({saveSuccess: false})
        }, 5000);
      })
      .catch(error => {
        this.setState({ saveErrorMessage: error.message, loading: false, })
        console.error("error when fetching", error);
      })
  }

  selectDataToSubmit(state) {
    state = JSON.parse(JSON.stringify(state))
    filterObject(state, "createdAt")
    filterObject(state, "numProspects")
    filterObject(state, "numProspectsWithoutSearch")
    filterObject(state, "prospectDistributionStatus")
    filterObject(state, "updatedAt")
    filterObject(state, "numBlacklistedProspects")
    filterObject(state, "numLeftProspects")
    filterObject(state, "automaticDailyRequestTarget")
    filterObject(state, "automaticPeopleCountToKeep")
    filterObject(state, "exportUrl")
    filterObject(state, "phantombusterAgentId")
    filterObject(state, "phantombusterErrors")
    filterObject(state, "usedCredits")
    filterObject(state, "totalCredits")
    filterObject(state, "openForEditing")
    filterObject(state, "numDelivered")
    filterObject(state, "numAccepted")
    filterObject(state, "linkedInAccountName")
    filterObject(state, "numNotAccepted")
    filterObject(state, "numAcceptedNotAnswered")
    filterObject(state, "numAnswered")
    filterObject(state, "numRepliedAfterStage")
    filterObject(state, "numContactedProspects")
    filterObject(state, "genderedSalutes")
    filterObject(state, "campaignStati")
    filterObject(state, "numConnectionErrorsAfterDeadlineWhereErrorsCount")
    filterObject(state, "numConnectionErrors")
    filterObject(state, "numNotContactedAndBlacklisted")
    filterObject(state.company.searches, "status")
    filterObject(state.company.campaigns, "numProspects")
    filterObject(state.company.campaigns, "numAssignedNotContactedProspects")
    filterObject(state.company.campaigns, "numBlacklisted")
    filterObject(state.company.campaigns, "numGenderUnknown")
    filterObject(state.company.searches, "queries")
    filterObject(state, "companyId")
    filterObject(state, "lastSyncedAt")
    filterObject(state, "errors")
    filterObject(state, "patchUrl")
    filterObject(state, "nextProspectsUrl")
    filterObject(state, "showUrl")
    filterObject(state, "key")
    filterObject(state.company.blacklistImports, "status")
    filterObject(state.company.blacklistImports, "numBlacklisted")
    filterObject(state.company.campaigns, "prospectPools")
    let linkedInAccounts = state.linkedInAccounts.filter(acc => acc.dirty || acc.frontendId !== acc.id)
    linkedInAccounts.forEach(acc => delete acc.dirty)
    return { company: state.company, linkedInAccounts, };

    function filterObject(obj, key) {
      for (var i in obj) {
        if (!obj.hasOwnProperty(i)) continue;
        if (i == key) {
          delete obj[key];
        } else if (typeof obj[i] == 'object') {
          filterObject(obj[i], key);
        }
      }
    }
  }

  resetMessages() {
  }


  render () {
    let { company, saveErrorMessage, saveSuccess, hasLinkedInAccountErrors, } = this.state;
    let { searches, campaigns, blacklistImports, prospectPools, creditBookings } = company;
    return (
      <div data-test-id="company-form">

        <div style={{
          position: "fixed",
          left: 0,
          top: 10,
          zIndex: 10,
          width: "100%",
          padding: "10px",
        }}>
        <Grid>
          <Grid.Column width={3} floated='right'>
            {present(saveErrorMessage) &&
                <Message
                  error
                  header={"Error when saving."}
                  content={this.state.saveErrorMessage}
                />
            }
            {saveSuccess &&
                <Message
                  success
                  header={"Passt - neh'ma!"}
                  content={'Data saved succesfully.'}
                />
            }
            {(present(company.errors) || hasLinkedInAccountErrors) &&
                <Message
                  error
                  header='Des is a Bledsinn, oida!'
                  content={'Invalide sind rot gekennzeichnet.'}
                />
            }
          </Grid.Column>
        </Grid>
      </div>

      <h2>Credits</h2>
      <CreditBookings
        creditBookings={creditBookings}
        usedCredits={company.usedCredits}
        totalCredits={company.totalCredits}
        onChange={this.handleCreditBookingsChange}
        handleSubmit={this.handleSubmit}
        loading={this.state.loading}
      />


    <h2>Blacklist Imports</h2>
    <BlacklistImports
      blacklistImports={blacklistImports}
      onChange={this.handleBlacklistImportsChange}
      handleSubmit={this.handleSubmit}
      loading={this.state.loading}
    />

  <h2>Searches</h2>
  <div>
    Prospects without search: {company.numProspectsWithoutSearch || 0}
  </div>
  <Searches
    searches={searches}
    onChange={this.handleSearchesChange}
    handleSubmit={this.handleSubmit}
    loading={this.state.loading}
    linkedInAccounts={this.state.linkedInAccounts}
    onLinkedInAccountsChange={this.handleLinkedInAccountsChange.bind(this)}
  />

<h2>Prospect Pools</h2>
<ProspectPools
  prospectPools={prospectPools}
  onChange={this.handleProspectPoolsChange}
  handleSubmit={this.handleSubmit}
  loading={this.state.loading}
/>

        <h2>Campaigns</h2>
        <Campaigns
          campaigns={campaigns}
          searches={searches}
          genderedSalutes={company.genderedSalutes}
          campaignStati={company.campaignStati}
          prospectPools={prospectPools}
          linkedInAccounts={this.state.linkedInAccounts}
          onChange={this.handleCampaignsChange}
          onLinkedInAccountsChange={this.handleLinkedInAccountsChange.bind(this)}
          onSubmit={this.handleSubmit}
          loading={this.state.loading}
        />


      <div>
        Prospect Distribution Status: {company.prospectDistributionStatus || "-"}
      </div>


    </div>
    )
  }
}

class CreditBookings extends React.Component {
  handleAddCreditBookingClick() {
    this.props.onChange([
      ...this.props.creditBookings,
      { frontendId: uuidv1(), bookingDate: new Date() }
    ])
  }

  handleInputChange(id, event) {
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;

    let creditBookings = [...this.props.creditBookings]
    const toChange = creditBookings.find(s => s.frontendId === id)
    toChange[name] = value
    this.props.onChange(creditBookings)
  }

  removeCreditBooking(id) {
    let creditBookings = [...this.props.creditBookings]
    const toDelete = creditBookings.find(s => s.frontendId === id)
    toDelete._destroy = "1"
    this.props.onChange(creditBookings)
  }

  handleDateChange(id, newDate) {
    let creditBookings = [...this.props.creditBookings]
    const toChange = creditBookings.find(s => s.frontendId === id)
    toChange.bookingDate = newDate;
    this.props.onChange(creditBookings);
  }

  renderCreditBookings() {
    if (!this.props.creditBookings || this.props.creditBookings.length == 0) {
      return (
        <div>
          <h3 style={{textAlign: "center"}}>No credits yet.</h3>
        </div>
      );
    }
    return this.props.creditBookings.filter(b => !present(b._destroy)).map(booking => {
      let onChange = (event) => {this.handleInputChange(booking.frontendId, event)}
      onChange = onChange.bind(this)
      return (
        <Form key={booking.frontendId}>
          <Grid columns={"equal"}>
            <Grid.Column>
              { formInput(booking, "name", "Name", onChange) }
            </Grid.Column>
            <Grid.Column>
              { formInput(booking, "creditAmount", "Amount", onChange) }
            </Grid.Column>
            <Grid.Column>
              <Form.Field error={errorFor(booking, "bookingDate")}>
                <label>Date</label>
                <DatePicker
                  dateFormat={"dd.MM.yyyy"}
                  selected={(typeof booking.bookingDate === "string" && booking.bookingDate !== "") ? new Date(booking.bookingDate) : booking.bookingDate}
                  onChange={this.handleDateChange.bind(this, booking.frontendId)}
                />
                {errorFor(booking, "bookingDate") &&
                    <div class="ui pointing above prompt label">{errorFor(booking, "bookingDate")}</div>
                }
              </Form.Field>
            </Grid.Column>
            <Grid.Column width={1}>
              <Form.Field>
                <label>&nbsp;</label>
                <Button type="button" onClick={this.removeCreditBooking.bind(this, booking.frontendId)} icon><Icon name="trash" /></Button>
              </Form.Field>
            </Grid.Column>

          </Grid>
        </Form>
      );

    });
  }

  render() {
    let { usedCredits, totalCredits } = this.props
    let percent = totalCredits === 0 ? 100 : Math.round(100*usedCredits/totalCredits)
    let error = totalCredits-usedCredits < 250
    return (
      <Segment>
        <Grid>

          <Grid.Column width={16}>
            <Progress percent={percent} size='small' error={error} progress>
              {usedCredits}/{totalCredits}
            </Progress>
            { this.renderCreditBookings() }
          </Grid.Column>

          <Grid.Column width={5} floated="left">
            <Button type="button"
              onClick={this.handleAddCreditBookingClick.bind(this)}
              icon="add"
              labelPosition="left"
              content={"Add credits"}
            />
          </Grid.Column>
          <Grid.Column width={5} floated="right">
            <Button type="button" onClick={this.props.handleSubmit} loading={this.props.loading} positive floated="right">Save</Button>
          </Grid.Column>
        </Grid>
      </Segment>
    );
  }
}

class Campaigns extends React.Component {

  constructor(props) {
    super(props)
  }

  componentDidMount() {
    //this.handleAddCampaignClick();
  }

  handleInputChange(id, event, setStateCallback) {
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;

    let campaigns = [...this.props.campaigns]
    const toChange = campaigns.find(c => c.frontendId === id)
    toChange[name] = value
    this.props.onChange(campaigns, setStateCallback)
  }

  handleLinkedInProfileScraperChange(id, event) {
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;
    console.log("before", this.props.campaigns)

    let campaigns = [...this.props.campaigns]
    const toChange = campaigns.find(c => c.frontendId === id).linkedInProfileScraper
    toChange[name] = value
    console.log("after", campaigns)
    this.props.onChange(campaigns)
  }

  handleSegmentsChange(id, segments, bar) {
    let campaigns = [...this.props.campaigns]
    const toChange = campaigns.find(c => c.frontendId === id)
    toChange.segments = [ ...segments ]
    this.props.onChange(campaigns)
  }

  handleSearchAssociationsChange(id, assocs) {
    let campaigns = [...this.props.campaigns]
    const toChange = campaigns.find(c => c.frontendId === id)
    toChange.campaignSearchAssociations = [ ...assocs ]
    this.props.onChange(campaigns)
  }

  handleProspectPoolAssociationChange(id, assocs) {
    let campaigns = [...this.props.campaigns]
    const toChange = campaigns.find(c => c.frontendId === id)
    toChange.prospectPoolCampaignAssociations = [ ...assocs ]
    this.props.onChange(campaigns)
  }

  handleStatusChange(id, event, data) {
    let campaigns = [...this.props.campaigns]
    const toChange = campaigns.find(c => c.frontendId === id)
    toChange.status = data.value
    this.props.onChange(campaigns)
  }

  handleAddCampaignClick(scriptType) {
    this.props.onChange([
      ...this.props.campaigns,
      { scriptType: scriptType || "LLG", frontendId: uuidv1(), status: "3", linkedInAccountId: null, prospectPoolCampaignAssociations: [{prospectPoolId: this.props.prospectPools[0].id, frontendId: uuidv1(), }], campaignSearchAssociations: [], openForEditing: true, followUpStagesToCountAsCreditUse: [], followUps: [{daysDelay: "0", message: ""}], manualControl: false, manualDailyRequestTarget: 30, manualPeopleCountToKeep: 300, shouldSaveToPhantombuster: false, linkedInProfileScraper: { active: false, dailyScrapingTarget: 40 } }
    ])
  }

  handleEditingStatusChanged(id, value) {
    let campaigns = [...this.props.campaigns]
    const toChange = campaigns.find(c => c.frontendId === id)
    toChange.openForEditing = value
    this.props.onChange(campaigns)
  }

  handleFollowUpStagesToCountAsCreditUseChange(id, event, data) {
    let campaigns = [...this.props.campaigns]
    const toChange = campaigns.find(c => c.frontendId === id)
    toChange.followUpStagesToCountAsCreditUse = data.value
    this.props.onChange(campaigns)
  }

  handleFollowUpsChange(id, followUps, setStateCallback) {
    let campaigns = [...this.props.campaigns]
    const toChange = campaigns.find(c => c.frontendId === id)
    toChange.followUps = followUps;
    this.props.onChange(campaigns, setStateCallback)
  }

  renderCampaigns() {
    return this.props.campaigns.map(campaign => {
      let onChange = (event, setStateCallback) => {this.handleInputChange(campaign.frontendId, event, setStateCallback)}
      onChange = onChange.bind(this)
      let onSegmentsChange = (segments) => {this.handleSegmentsChange(campaign.frontendId, segments)}
      onSegmentsChange = onSegmentsChange.bind(this)
      let onLinkedInAccountChange = (account) => { this.handleLinkedInAccountChange(campaign.frontendId, account) }
      onLinkedInAccountChange = onLinkedInAccountChange.bind(this)
      let onNewLinkedInAccountClick = () => { this.handleNewLinkedInAccountClick(campaign.frontendId) }
      onNewLinkedInAccountClick = onNewLinkedInAccountClick.bind(this)
      let onEditLinkedInAccountClick = () => { this.handleEditLinkedInAccountClick(campaign.frontendId) }
      onEditLinkedInAccountClick = onEditLinkedInAccountClick.bind(this)
      let onFinishedEditingLinkedInAccount = () => { this.handleFinishedEditingLinkedInAccountClick(campaign.frontendId) }
      onFinishedEditingLinkedInAccount = onFinishedEditingLinkedInAccount.bind(this)
      let onSearchAssociationsChange = (assocs) => { this.handleSearchAssociationsChange(campaign.frontendId, assocs) }
      onSearchAssociationsChange = onSearchAssociationsChange.bind(this)
      let onProspectPoolAssociationChange = (assocs) => { this.handleProspectPoolAssociationChange(campaign.frontendId, assocs) }
      onProspectPoolAssociationChange = onProspectPoolAssociationChange.bind(this)
      let onStatusChange = (event, data) => { this.handleStatusChange(campaign.frontendId, event, data) }
      onStatusChange = onStatusChange.bind(this)
      let onEditingStatusChanged = (value) => { this.handleEditingStatusChanged(campaign.frontendId, value) }
      onEditingStatusChanged = onEditingStatusChanged.bind(this)
      let onFollowUpStagesToCountAsCreditUseChange = (event, data) => { this.handleFollowUpStagesToCountAsCreditUseChange(campaign.frontendId, event, data) }
      onFollowUpStagesToCountAsCreditUseChange = onFollowUpStagesToCountAsCreditUseChange.bind(this)
      let onFollowUpsChange = (newFollowUps, setStateCallback) => { this.handleFollowUpsChange(campaign.frontendId, newFollowUps, setStateCallback) }
      onFollowUpsChange = onFollowUpsChange.bind(this)
      let onLinkedInProfileScraperChange = (event) => { this.handleLinkedInProfileScraperChange(campaign.frontendId, event) }
      onLinkedInProfileScraperChange = onLinkedInProfileScraperChange.bind(this)
      return (
        <CampaignForm
          key={campaign.frontendId}
          campaign={campaign}
          onSubmit={this.props.onSubmit}
          loading={this.props.loading}
          searches={this.props.searches}
          prospectPools={this.props.prospectPools}
          linkedInAccounts={this.props.linkedInAccounts}
          onChange={onChange}
          onSegmentsChange={onSegmentsChange}
          onLinkedInAccountsChange={this.props.onLinkedInAccountsChange}
          onLinkedInAccountChange={onLinkedInAccountChange}
          onNewLinkedInAccountClick={onNewLinkedInAccountClick}
          onEditLinkedInAccountClick={onEditLinkedInAccountClick}
          onFinishedEditingLinkedInAccount={onFinishedEditingLinkedInAccount}
          onSearchAssociationsChange={onSearchAssociationsChange}
          onProspectPoolAssociationChange={onProspectPoolAssociationChange}
          onStatusChange={onStatusChange}
          changeEditingStatus={onEditingStatusChanged}
          onFollowUpStagesToCountAsCreditUseChange={onFollowUpStagesToCountAsCreditUseChange}
          onFollowUpsChange={onFollowUpsChange}
          onLinkedInProfileScraperChange={onLinkedInProfileScraperChange}
          genderedSalutes={this.props.genderedSalutes}
          campaignStati={this.props.campaignStati}
        />
      );
    });
  }

  addButtons() {
    return (
      <Button.Group>
        <Button type="button" icon
          onClick={this.handleAddCampaignClick.bind(this, "LLG")}
          labelPosition="left"
        >

        <i className="fas fa-user-plus icon"></i>
        Add LLG
      </Button>
      <Button.Or />
      <Button type="button"
        onClick={this.handleAddCampaignClick.bind(this, "LM")}
        labelPosition="right"
        icon
      >
        <i className="fas fa-envelope icon"></i>
        LM campaign
      </Button>
    </Button.Group>
    );

  }

  render () {
    if (!present(this.props.campaigns)) {
      return (
        <div style={{textAlign: "center"}}>
          <Header as="h3">No campaigns yet.</Header>
          { this.addButtons() }
        </div>
      );
    }
    return (
      <div>

        <div className="campaignsList" style={{width:"100%", marginBottom: 25}}>
          { this.renderCampaigns() }
        </div>
        <Grid>
          <Grid.Column width="5" floated="left">
            { this.addButtons() }
          </Grid.Column>
          <Grid.Column width="5" floated="right">
            <Button type="button" onClick={this.props.onSubmit} loading={this.props.loading} positive floated="right">Save</Button>
          </Grid.Column>
        </Grid>
      </div>
    );
  }
}

class CampaignForm extends React.Component {



  render() {
    let { onChange, onLinkedInProfileScraperChange, onSegmentsChange, onLinkedInAccountChange, onNewLinkedInAccountClick, onEditLinkedInAccountClick, onSearchAssociationsChange, onProspectPoolAssociationChange, onStatusChange, campaign, searches, prospectPools, linkedInAccounts, onFollowUpStagesToCountAsCreditUseChange, onFollowUpsChange, genderedSalutes, campaignStati, onFinishedEditingLinkedInAccount,} = this.props

    if (!this.props.campaign.openForEditing && !present(this.props.campaign.errors)) {
      return (
        <CampaignPreview
          key={campaign.frontendId}
          campaign={this.props.campaign}
          canSeeColorCode={true}
          noRed={false}
          showAdminInfo={true}
          canEdit={this.props.canEdit}
          canSeeDetails={this.props.canSeeDetails}

          renderActions={(props) => {
            return (
              <div>
                <Button type="button" icon onClick={() => { this.props.changeEditingStatus(true)}} aria-label="Edit">
                  <Icon name="edit" />
                </Button>
                <a href={`/backend/campaigns/${campaign.id}`} className="ui button" aria-label="Details" target="_blank">
                  <i className="far fa-eye icon"></i>
                </a>
              </div>
            );
          }}

        />
      );
    }
    return (
      <Segment key={campaign.frontendId}
        data-test-id={"campaign-form"}
      >
        <ScriptType scriptType={campaign.scriptType} backgroundColor="rgba(34, 36, 38, 0.15)"/>
        <Form error={present(campaign.errors) || present(campaign.phantombusterErrors)}>
          <Grid columns='equal'>
            <Grid.Row>
              <Grid.Column floated='left' width={8}>
                <Header as="h1">
                  {campaign.name}
                </Header>
              </Grid.Column>
              <Grid.Column floated='right' width={1}>
                <Button type="button" icon onClick={() => { this.props.changeEditingStatus(false) }}>
                  <Icon name="close" />
                </Button>
              </Grid.Column>
            </Grid.Row>
            { present(campaign.phantombusterErrors) && <Grid.Row>
              <Grid.Column width={16}>
                <Message
                  error
                  header={"This campaign will never run."}
                  content={campaign.phantombusterErrors}
                />
              </Grid.Column>
            </Grid.Row>
            }
            <Grid.Column width={5} data-test-id="campaign-name">
              { formInput(campaign, "name", "Name", onChange) }
            </Grid.Column>
            <Grid.Column>
              { formInput(campaign, "nextMilestone", "Next Milestone", onChange) }
            </Grid.Column>
            <Grid.Column>
              { formInput(campaign, "targetAudienceSize", "Target Audience Size", onChange) }
            </Grid.Column>
            <Grid.Column>
              <Form.Field>
                <label>Status</label>
                <Form.Select
                  error={present(errorFor(campaign, "status"))}
                  fluid
                  selection
                  name="status"
                  options={
                    campaignStati.map(status => {
                      return {
                        key: status.key,
                        value: status.key,
                        text: status.description,
                      };
                    })
                  }
                  value={campaign.status}
                  onChange={onStatusChange}
                  placeholder='Status'
                />
              </Form.Field>
            </Grid.Column>

            <Grid.Row data-test-id="new-linked-in-account">
              <LinkedInAccountSelectionAndForm
                linkedInAccounts={this.props.linkedInAccounts}
                onLinkedInAccountsChange={this.props.onLinkedInAccountsChange}
                onLinkedInAccountSelectionChange={onChange}
                selectedLinkedInAccountId={campaign.linkedInAccountId}
                selectionError={errorFor(campaign, "linkedInAccount")}
              />
            </Grid.Row>

            <Grid.Column width={16}>
              <CampaignSearchAssociations
                searches={searches}
                campaignSearchAssociations={campaign.campaignSearchAssociations}
                onChange={onSearchAssociationsChange}
              />
            </Grid.Column>

            <Grid.Column width={16}>
              <ProspectPoolCampaignAssociations
                prospectPoolCampaignAssociations={campaign.prospectPoolCampaignAssociations}
                prospectPools={prospectPools}
                onChange={onProspectPoolAssociationChange}
              />
            </Grid.Column>

            <Grid.Column width={16}>
              <MessageEditor
                campaign={campaign}
                onChange={onChange}
                onFollowUpsChange={onFollowUpsChange}
                genderedSalutes={genderedSalutes}
              />
            </Grid.Column>

            <Grid.Row>
              <Grid.Column width={16} style={{marginBottom: 16}}>
                { formInput(campaign, "shouldSaveToPhantombuster", "Save to Phantombuster? NICHT ANFASSEN!", onChange, Form.Checkbox, { slider: true } ) }
              </Grid.Column>
              <Grid.Column width={16} style={{marginBottom: 16}}>
                { formInput(campaign, "manualControl", "Manual Override", onChange, Form.Checkbox, { slider: true} ) }
              </Grid.Column>
              {campaign.manualControl && <React.Fragment>
                <Grid.Column width={4}>
                  { formInput(campaign, "manualDailyRequestTarget", "Daily Request Target", onChange) }
                </Grid.Column>
                <Grid.Column width={4}>
                  { formInput(campaign, "manualPeopleCountToKeep", "People Count To Keep", onChange) }
                </Grid.Column>
              </React.Fragment>
              }
              {!campaign.manualControl && <React.Fragment>
                <Grid.Column width={4}>
                  Current Automatic Daily Requests: { campaign.automaticDailyRequestTarget}
                </Grid.Column>
                <Grid.Column width={4}>
                  Current Automatic People Count To Keep: { campaign.automaticPeopleCountToKeep}
                </Grid.Column>
              </React.Fragment>
              }
              <Grid.Column>
                { formInput(campaign.linkedInProfileScraper, "active", "Scrape Profiles?", onLinkedInProfileScraperChange, Form.Checkbox, { slider: true } ) }
                { campaign.linkedInProfileScraper.active && <React.Fragment>
                  { formInput(campaign.linkedInProfileScraper, "dailyScrapingTarget", "Daily Scraping Target", onLinkedInProfileScraperChange) }
                    </React.Fragment>
                }
              </Grid.Column>
              <Grid.Column>
                {
                  formInput(
                    campaign,
                    "timezone",
                    "Timezone",
                    onChange,
                    Form.Select,
                    {
                      search: true,
                      options: window.timezones,
                    }
                  )
                }
              </Grid.Column>
            </Grid.Row>


            <Grid.Row>
              <Grid.Column>
                <CampaignSegments
                  segments={present(campaign.segments) ? campaign.segments : [{name: "", date: ""}]}
                  onChange={onSegmentsChange}
                />
              </Grid.Column>
            </Grid.Row>

            <Grid.Row>
              <Grid.Column>
                <h3>Followups that count as credit use</h3>
                <Dropdown
                  multiple
                  fluid
                  search
                  selection
                  options={[
                    {key:'1',value:'1',text: 'first followup'},
                    {key:'2',value:'2',text: 'second followup'},
                    {key:'3',value:'3',text: 'third followup'},
                    {key:'4',value:'4',text: 'fourth followup'},
                    {key:'5',value:'5',text: 'fifth followup'},
                    {key:'6',value:'6',text: 'sixth followup'},
                    {key:'7',value:'7',text: 'seventh followup'},
                    {key:'8',value:'8',text: 'eigth followup'},
                    {key:'9',value:'9',text: 'ninth followup'},
                    {key:'10',value:'10',text: 'tenth followup'},
                  ]}
                  placeholder="Followups that count as credit use"
                  onChange={onFollowUpStagesToCountAsCreditUseChange}
                  value={campaign.followUpStagesToCountAsCreditUse}
                />

            </Grid.Column>
          </Grid.Row>

          <Grid.Row>
            <Grid.Column>
              <Form.Field>
                <label>Notes</label>
                <textarea value={campaign.notes || ""} name="notes" onChange={onChange} />
              </Form.Field>
            </Grid.Column>
          </Grid.Row>
          <Grid.Row>
            <Grid.Column>
              Total assigned prospects: {campaign.numProspects || 0}
              <br />
              Assigned but not contacted prospects: {campaign.numAssignedNotContactedProspects || 0}
              <br />
              Total Blacklisted: {campaign.numBlacklisted || 0}
              <br />
              Unused and Blacklisted: {campaign.numNotContactedAndBlacklisted || 0}
              <br />
              { campaign.nextProspectsUrl && <a href={campaign.nextProspectsUrl+"&limit=5000000"}>Next Prospects</a> }
              <br />
              { present(campaign.phantombusterAgentId) && <div>
                <a href={"https://phantombuster.com/26621/phantoms/"+campaign.phantombusterAgentId} target="_blank">Link to PB ({ campaign.phantombusterAgentId })</a>
              </div> }
            </Grid.Column>
          </Grid.Row>
          <Grid.Column>
            <Button type="button" onClick={this.props.onSubmit} loading={this.props.loading}>Save</Button>
          </Grid.Column>
        </Grid>
      </Form>
    </Segment>
    );
  }
}

class MessagePreview extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      preview: "",
      charCount: 0,
      loading: true,
      error: null,
    }
    this.debouncedLoadPreview = _.debounce(this.loadPreview.bind(this), 100)
  }

  componentDidMount() {
    this.debouncedLoadPreview();
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.template !== this.props.template) {
      this.debouncedLoadPreview();
    }
  }

  loadPreview() {
    if (this.lastCancelSource) { this.lastCancelSource.cancel(); }

    if (!present(this.props.template)) {
      this.setState({
        preview: "",
        charCount: 0,
        error: null,
        loading: false,
      });
      return;
    }

    this.lastCancelSource = axios.CancelToken.source();

    this.setState({loading: true})
    axios.post("/api/populate_message/", {
      message: this.props.template,
      data: {
        name: "Magdalena Musterfrau",
      },
    }, {
      cancelToken: this.lastCancelSource.token,
    })
      .then(({data}) => {
        this.setState({
          loading: false,
          preview: data.message,
          charCount: data.charCount,
          error: null,
        });
      })
      .catch(error => {
        if (axios.isCancel(error)) {
          console.log("canceled");
          return;
        }
        console.log(error);
        this.setState({
          loading: false,
          error: error.message,
        })
      });
  }


  render() {
    return (
      <div>
        <Form.Field>
          <label>
            Preview ({this.state.charCount})&nbsp;&nbsp;
            <Loader size='mini' className="showAfterOneSecond" active={this.state.loading} inline />
          </label>
          <div style={{whiteSpace: "pre-wrap"}}>
            { this.state.preview }
          </div>
        </Form.Field>
      </div>
    );
  }
}

class MessageEditor extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      messageWithFocus: null,
    }
    this.messageRefs = {};
  }

  handleAddFollowUp() {
    let newFollowUps = [...this.props.campaign.followUps]
    newFollowUps.push({
      message: "",
      daysDelay: newFollowUps.length == 0 ? "0" : "1",
    });
    let cursorSetter = () => {
      let textarea = this.messageRefs[newFollowUps.length-1].getElementsByTagName('textarea')[0]
      textarea.focus();
    };
    this.props.onFollowUpsChange(newFollowUps, cursorSetter);
  }

  handleRemoveFollowUp(removeIndex) {
    let newFollowUps = [...this.props.campaign.followUps]
    newFollowUps = this.props.campaign.followUps.filter((x, i) => i !== removeIndex)
    this.props.onFollowUpsChange(newFollowUps);
  }

  handleFollowUpsChange(index, event, data, setStateCallback) {
    let newFollowUps = [...this.props.campaign.followUps]
    newFollowUps[index][event.target.name] = event.target.value;
    this.props.onFollowUpsChange(newFollowUps, setStateCallback);
  }

  renderFollowUps() {
    let { campaign, onFollowUpsChange, } = this.props;
    return campaign.followUps.map((followUp, i) => {
      let handleFollowUpsChange = (event, data) => { this.handleFollowUpsChange(i, event, data) }
      return (
        <div key={i} style={{marginBottom: 14}} ref={this.setRef.bind(this, i)} data-test-id={"follow-up-"+i}>
          <Segment>
            <Grid>
              <Grid.Row>
                <Grid.Column width={12} floated="left">
                  <Header as={"h3"}>Follow up {i+1}</Header>
                </Grid.Column>


                <Grid.Column width={1} floated="right">
                  <Button type="button" onClick={() => {this.handleRemoveFollowUp(i)}} icon><Icon name="trash" /></Button>
                </Grid.Column>
              </Grid.Row>
            </Grid>
            {
              formInput(
                { ...followUp, daysDelay: ""+followUp.daysDelay },
                "daysDelay",
                "When",
                handleFollowUpsChange,
                Form.Select,
                {
                  options: [
                    {key: "0", value: "0", text: "as soon as possible"},
                    {key: "1", value: "1", text: "after one day", },
                    ...(_.range(2,90).map(i => { return {key: ""+i, value: ""+i, text: `after ${i} days`, } }))
                  ],
                }
              )
            }
            <Grid>
              <Grid.Column width={8}>

                {
                  formInput(
                    followUp,
                    "message",
                    "Message",
                    handleFollowUpsChange,
                    Form.TextArea,
                    {
                      onFocus: this.handleTextAreaActivity.bind(this, i),
                      onBlur: this.handleTextAreaActivity.bind(this, i),
                      style: { minHeight: 300 },
                    },
                  )
                }
              </Grid.Column>
              <Grid.Column width={8}>
                <MessagePreview template={followUp.message} />
              </Grid.Column>

            </Grid>
          </Segment>
        </div>
      );
    });
  }

  handleTextAreaActivity(index, event) {
    this.setState({
      messageWithFocus: index,
      selectionStart: event.target.selectionStart,
      selectionEnd: event.target.selectionEnd
    })
  }

  handleInsertTemplateVar(templateVar) {
    let messageIndex = this.state.messageWithFocus === null ? -1 : this.state.messageWithFocus;
    let originalSelectionStart = this.state.selectionStart || 0;
    let cursorSetter = () => {
      let textarea = this.messageRefs[messageIndex].getElementsByTagName('textarea')[0];
      textarea.focus();
      textarea.setSelectionRange(originalSelectionStart+templateVar.length, originalSelectionStart+templateVar.length);
    };
    if (messageIndex === -1) {
      this.props.onChange({ target: {
        value: this.getStringWithTemplateVar(this.props.campaign.message, templateVar),
        name: "message"
      }
      }, cursorSetter);
    } else {
      this.handleFollowUpsChange(messageIndex, {
        target: {
          value: this.getStringWithTemplateVar(this.props.campaign.followUps[messageIndex].message, templateVar),
          name: "message",
        }
      }, null, cursorSetter);
    }
  }

  getStringWithTemplateVar(string, templateVar) {
    if (!present(string)) { return templateVar; }
    return string.substring(0, this.state.selectionStart)
      + templateVar
      + string.substring(this.state.selectionEnd, string.length);
  }

  setRef(index, element) {
    this.messageRefs[index] = element;
  }


  render() {
    let { campaign, onChange, genderedSalutes, } = this.props;
    return (
      <div ref={this.setRef.bind(this, -1)}>
        <Grid>

          <Grid.Column width={16}>
            { genderedSalutes.map(salute => {
              return (
                <Button
                  type="button"
                  content={salute.male}
                  key={salute.key}
                  onClick={this.handleInsertTemplateVar.bind(this, salute.key+(salute.ui_append||""))}
                />
              );
            })}

            <Button
              type="button"
              content={"first name"}
              onClick={this.handleInsertTemplateVar.bind(this, "#firstName#")}
            />
            <Button
              type="button"
              content={"last name"}
              onClick={this.handleInsertTemplateVar.bind(this, "#lastName#")}
            />
          </Grid.Column>
        </Grid>

        <Segment>
          <Header as={"h3"}>Connection Message</Header>
          <Grid>
            <Grid.Column width={8} data-test-id="connection-message">
              { formInput(
                campaign,
                "message",
                "Connection Message",
                onChange,
                Form.TextArea,
                {
                  onBlur: this.handleTextAreaActivity.bind(this, -1),
                  style: { minHeight: 300 }
                }
              )
              }
            </Grid.Column>
            <Grid.Column width={8}>
              <MessagePreview template={campaign.message} />
            </Grid.Column>
          </Grid>
        </Segment>

        { this.renderFollowUps() }
        <Button type="button"
          onClick={this.handleAddFollowUp.bind(this)}
          icon="add"
          labelPosition="left"
          content={"Add follow up"}
        />
      </div>
    );
  }
}

class ProspectPools extends React.Component {

  handleAddProspectPoolClick() {
    this.props.onChange([
      ...this.props.prospectPools,
      { frontendId: uuidv1() }
    ])
  }

  handleInputChange(id, event) {
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;

    let prospectPools = [...this.props.prospectPools]
    const toChange = prospectPools.find(s => s.frontendId === id)
    toChange[name] = value
    this.props.onChange(prospectPools)
  }

  removeProspectPool(id) {
    let prospectPools = [...this.props.prospectPools]
    const filtered = prospectPools.filter(s => s.frontendId !== id)
    this.props.onChange(filtered)
  }

  renderProspectPools() {
    if (!this.props.prospectPools || this.props.prospectPools.length == 0) {
      return (
        <div>
          <h3>No prospect pools yet.</h3>
        </div>
      );
    }
    return this.props.prospectPools.map(prospectPool => {
      let onChange = (event) => {this.handleInputChange(prospectPool.frontendId, event)}
      onChange = onChange.bind(this)
      return (
        <Segment key={prospectPool.frontendId}>
          <Form>
            <Grid columns="equal" >

              <Grid.Column>
                { formInput(prospectPool, "name", "Name", onChange) }
              </Grid.Column>
              { !present(prospectPool.id) && <Grid.Column width={1}>
                <Form.Field>
                  <label>&nbsp;</label>
                  <Button type="button" onClick={this.removeProspectPool.bind(this, prospectPool.frontendId)} icon><Icon name="trash" /></Button>
                </Form.Field>
              </Grid.Column>
              }
            </Grid>
          </Form>
        </Segment>
      );
    });
  }
  render () {
    return (
      <Grid>
        <Grid.Column width={16}>
          { this.renderProspectPools() }
        </Grid.Column>
        <Grid.Column width={5} floated="left">
          <Button type="button"
            onClick={this.handleAddProspectPoolClick.bind(this)}
            icon="add"
            labelPosition="left"
            content={"Add prospect pool"}
          />
        </Grid.Column>
        <Grid.Column width={5} floated="right">
        </Grid.Column>
      </Grid>
    );
  }
}

class LinkedInAccountSelectionAndForm extends React.Component {

  constructor(props) {
    super(props)
    this.state = {
      editingAccount: false,
    }
  }

  getLinkedInAccount() {
    return this.props.linkedInAccounts.find(acc => acc.frontendId == this.props.selectedLinkedInAccountId || acc.id == this.props.selectedLinkedInAccountId)
  }

  onEditingLinkedInAccountChange(account) {
    let linkedInAccounts = [...this.props.linkedInAccounts];
    const toChangeIndex = linkedInAccounts.findIndex(a => a.frontendId === account.frontendId)
    account.dirty = true
    linkedInAccounts[toChangeIndex] = account;
    this.props.onLinkedInAccountsChange(linkedInAccounts);
  }

  handleFinishedEditingClick() {
    // destroys a non-created account to avoid confusion
    if (!present(this.getLinkedInAccount().id)) {
      let linkedInAccounts = this.props.linkedInAccounts.filter(a => a.frontendId !== this.getLinkedInAccount().frontendId)
      this.props.onLinkedInAccountsChange(linkedInAccounts);
      this.props.onLinkedInAccountSelectionChange({ target: { value: null, name: "linkedInAccountId", } });
    }
    this.setState({ editingAccount: false, });
  }

  handleEditLinkedInAccountClick() {
    this.setState({ editingAccount: true, });
  }

  handleNewLinkedInAccountClick() {
    let newAccount = { frontendId: uuidv1(), dirty: true, }
    let linkedInAccounts = [...this.props.linkedInAccounts, newAccount];
    this.props.onLinkedInAccountsChange(linkedInAccounts);
    this.props.onLinkedInAccountSelectionChange({ target: { value: newAccount.frontendId, name: "linkedInAccountId", } });
    this.setState({
      editingAccount: true,
    });
  }


  render() {

    if (present(this.getLinkedInAccount()) && (this.state.editingAccount || present(this.getLinkedInAccount().errors))) {
      return (
        <LinkedInAccountForm
          linkedInAccount={this.getLinkedInAccount()}
          onChange={this.onEditingLinkedInAccountChange.bind(this)}
          onFinishedEditing={this.handleFinishedEditingClick.bind(this)}
          disableFinishing={present(this.getLinkedInAccount().errors)}
           />
      );
    }

    return (
      <LinkedInAccountSelection
        linkedInAccounts={this.props.linkedInAccounts}
        selectionError={this.props.selectionError}
        selectedLinkedInAccountId={this.props.selectedLinkedInAccountId}
        onEditLinkedInAccountClick={this.handleEditLinkedInAccountClick.bind(this)}
        onNewLinkedInAccountClick={this.handleNewLinkedInAccountClick.bind(this)}
        onLinkedInAccountSelectionChange={this.props.onLinkedInAccountSelectionChange}
      />
    );
  }

}

class LinkedInAccountSelection extends React.Component {

  render() {
    let { linkedInAccounts, selectionError, selectedLinkedInAccountId, onEditLinkedInAccountClick, onNewLinkedInAccountClick, onLinkedInAccountSelectionChange, } = this.props;
    return (
      <React.Fragment>
        <Grid.Column>
          <Form.Field>
            <label>LinkedIn Account</label>
            <Form.Select
              error={selectionError}
              fluid
              search
              selection
              options={linkedInAccounts.map(ac => { return { key: ac.frontendId, value: ac.frontendId, text: ac.name }})}
              value={selectedLinkedInAccountId}
              onChange={adaptOnChangeToClassicFormOnChange(onLinkedInAccountSelectionChange)}
              name="linkedInAccountId"
              placeholder='Select LinkedIn Account'
            />
          </Form.Field>
        </Grid.Column>
        <Grid.Column width={1}>
          <Form.Field>
            <label>&nbsp;</label>
            <Button type="button" onClick={onEditLinkedInAccountClick} icon data-test-id="edit-linked-in-account"><Icon name="edit" /></Button>
          </Form.Field>
        </Grid.Column>
        <Grid.Column width={1}>
          <Form.Field>
            <label>&nbsp;</label>
            <Button type="button" onClick={onNewLinkedInAccountClick} icon data-test-id="add-linked-in-account"><Icon name="add" /></Button>
          </Form.Field>
        </Grid.Column>

      </React.Fragment>
    )
  }
}


class LinkedInAccountForm extends React.Component {
  handleInputChange(event) {
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;

    const account = {...this.props.linkedInAccount}
    account[name] = value
    this.props.onChange(account)
  }

  render() {
    let account = this.props.linkedInAccount;
    let onChange = this.handleInputChange.bind(this)
    return (
      <React.Fragment>
        <Grid.Column data-test-id="linked-in-account-name">
          { formInput(account, "name", "Name", onChange) }
        </Grid.Column>
        <Grid.Column>
          { formInput(account, "liAt", "li_at", onChange) }
        </Grid.Column>
        <Grid.Column>
          { formInput(account, "email", "Email", onChange) }
        </Grid.Column>
        <Grid.Column width={1} floated="right">
          <Form.Field>
            <label>&nbsp;</label>
            <Button type="button" disabled={this.props.disableFinishing} onClick={this.props.onFinishedEditing} icon data-test-id="finished-linked-in-account"><Icon name={present(account.id) ? "check" : "times"} /></Button>
          </Form.Field>
        </Grid.Column>
      </React.Fragment>
    )
  }
}

class CampaignSegments extends React.Component {
  constructor(props) {
    super(props);
  }

  handleDateChange(segmentKey, newDate) {
    let newSegments = [...this.props.segments]
    // convert to date format without hour information to prevent timezone issues changing the day
    newSegments[segmentKey].date = `${newDate.getFullYear()}-${newDate.getMonth()+1}-${newDate.getDate()}`;
    this.props.onChange(newSegments);
  }

  handleNameChange(segmentKey, event) {
    let newSegments = [...this.props.segments]
    newSegments[segmentKey].name = event.target.value;
    this.props.onChange(newSegments);
  }

  addSegment() {
    this.props.onChange([{ name: "", date: "" }, ...this.props.segments, ]);
  }

  removeSegment(key) {
    let newSegments = [...this.props.segments]
    newSegments.splice(key, 1)
    this.props.onChange(newSegments);
  }

  renderSegments() {
    let self = this;
    return this.props.segments.map((segment, index) => {
      return (
        <Grid.Row key={index}>

          <Grid.Column>
            <Form.Field>
              <label>Segment Name
                <input value={segment.name} name="name" onChange={this.handleNameChange.bind(this, index)} />
              </label>
            </Form.Field>

          </Grid.Column>

          <Grid.Column>
            <Form.Field>
              <label> Start Date
                <DatePicker
                  name={`campaign[segments][][date]`}
                  dateFormat={"dd.MM.yyyy"}
                  selected={(typeof segment.date === "string" && segment.date !== "") ? new Date(segment.date) : segment.date}
                  onChange={self.handleDateChange.bind(self, index)}
                /></label>
            </Form.Field>
          </Grid.Column>
          <Grid.Column width={1}>
            <Form.Field>
              <label>&nbsp;</label>
              <Button type="button" onClick={this.removeSegment.bind(this, index)} icon><Icon name="trash" /></Button>
            </Form.Field>
          </Grid.Column>
        </Grid.Row>
      );
    });
  }

  render () {
    return (
      <Grid columns='equal'>
        <Grid.Column width={16}>
          <h3>Segments</h3>
        </Grid.Column>

        { this.renderSegments() }

        <Grid.Column width={16}>
          <Button type="button"
            onClick={this.addSegment.bind(this)}
            icon="add"
            labelPosition="left"
            content={"Add Segment"}
          />
        </Grid.Column>

      </Grid>
    )
  }
}

class BlacklistImports extends React.Component {

  handleAddBlacklistImportClick() {
    this.props.onChange([
      ...this.props.blacklistImports,
      { frontendId: uuidv1(), type: "CompanyBlacklistImport", }
    ])
  }

  handleInputChange(id, event, data) {
    if (present(data)) { event = { target: data } }
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;

    let blacklistImports = [...this.props.blacklistImports]
    const toChange = blacklistImports.find(s => s.frontendId === id)
    toChange[name] = value
    this.props.onChange(blacklistImports)
  }

  removeBlacklistImport(id) {
    let blacklistImports = [...this.props.blacklistImports]
    const filtered = blacklistImports.filter(s => s.frontendId !== id)
    this.props.onChange(filtered)
  }

  renderBlacklistImports() {
    if (!this.props.blacklistImports || this.props.blacklistImports.length == 0) {
      return (
        <div>
          <h3>No blacklist imports yet.</h3>
        </div>
      );
    }
    return this.props.blacklistImports.map(blacklistImport => {
      let onChange = (event, data) => {this.handleInputChange(blacklistImport.frontendId, event, data)}
      onChange = onChange.bind(this)
      return (
        <Segment key={blacklistImport.frontendId}>
          <Form>
            <Grid columns="equal">

              <Grid.Column>
                { formInput(blacklistImport, "csvUrl", "CSV or Google Doc URL", onChange) }
              </Grid.Column>
              <Grid.Column width={4}>
                <Form.Field>
                  <label>Type</label>
                  <Dropdown
                    error={present(errorFor(blacklistImport, "type"))}
                    fluid
                    selection
                    options={[{key: "CompanyBlacklistImport", value: "CompanyBlacklistImport", text: "Company Blacklist"}, {key: "PersonBlacklistImport", value: "PersonBlacklistImport", text: "People Blacklist", }]}
                    value={blacklistImport.type}
                    name="type"
                    onChange={onChange}
                    placeholder='Type'
                  />
                </Form.Field>
              </Grid.Column>
              { !present(blacklistImport.id) && <Grid.Column width={1}>
                <Form.Field>
                  <label>&nbsp;</label>
                  <Button type="button" onClick={this.removeBlacklistImport.bind(this, blacklistImport.frontendId)} icon><Icon name="trash" /></Button>
                </Form.Field>
              </Grid.Column>
              }
              <Grid.Column width={16}>
                Status: {blacklistImport.status || "-"}
              </Grid.Column>
              <Grid.Column width={16}>
                blacklist size: {blacklistImport.numBlacklisted || 0}
              </Grid.Column>
            </Grid>
          </Form>
        </Segment>
      );
    });
  }
  render () {
    return (
      <Grid>
        <Grid.Column width={16}>
          { this.renderBlacklistImports() }
        </Grid.Column>
        <Grid.Column width={5} floated="left">
          <Button type="button"
            onClick={this.handleAddBlacklistImportClick.bind(this)}
            icon="add"
            labelPosition="left"
            content={"Add blacklist import"}
          />
        </Grid.Column>

        <Grid.Column width={5} floated="right">
          <Button type="button" onClick={this.props.handleSubmit} loading={this.props.loading} positive floated="right">Save</Button>
        </Grid.Column>
      </Grid>
    );
  }
}

class ProspectPoolCampaignAssociations extends React.Component {
  handleAddProspectPoolCampaignAssociationClick() {
    this.props.onChange([
      ...this.props.prospectPoolCampaignAssociations,
      { frontendId: uuidv1(), }
    ])
  }

  handleInputChange(id, event) {
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;

    let prospectPoolCampaignAssociations = [...this.props.prospectPoolCampaignAssociations]
    const toChange = prospectPoolCampaignAssociations.find(s => s.frontendId === id)
    toChange[name] = value
    this.props.onChange(prospectPoolCampaignAssociations)
  }

  handleProspectPoolCampaignAssociationSelectionChange(id, event, data) {
    let assocs = [...this.props.prospectPoolCampaignAssociations]
    const toChange = assocs.find(c => c.frontendId === id)
    toChange.prospectPoolId = this.props.prospectPools.find(s => data.value == s.id).id
    this.props.onChange(assocs)
  }

  removeProspectPoolCampaignAssociation(id) {
    let prospectPoolCampaignAssociations = [...this.props.prospectPoolCampaignAssociations]
    const filtered = prospectPoolCampaignAssociations.filter(s => s.frontendId !== id)
    this.props.onChange(filtered)
  }

  renderProspectPoolCampaignAssociations() {
    if (!this.props.prospectPoolCampaignAssociations || this.props.prospectPoolCampaignAssociations.length == 0) {
      return (
        <div>
          <h3>No prospect pools yet.</h3>
        </div>
      );
    }
    return this.props.prospectPoolCampaignAssociations.map(prospectPoolAssoc => {
      return (
        <Grid columns="equal" key={prospectPoolAssoc.frontendId}>

          <Grid.Column>
            <Form.Field>
              <label>Prospect Pool</label>
              <div style={{display: "flex"}}>
                <Dropdown
                  error={present(prospectPoolAssoc.errors)}
                  fluid
                  search
                  selection
                  allowAdditions
                  options={this.props.prospectPools.filter(s => present(s.id)).map(s => { return { key: s.id, value: s.id, text: s.name }})}
                  value={present(prospectPoolAssoc) ? prospectPoolAssoc.prospectPoolId : null}
                  onChange={this.handleProspectPoolCampaignAssociationSelectionChange.bind(this, prospectPoolAssoc.frontendId)}
                  placeholder='Select LinkedIn Account'
                />
              </div>
            </Form.Field>
          </Grid.Column>

          <Grid.Column width={1}>
            <Form.Field>
              <label>&nbsp;</label>
              <Button type="button" onClick={this.removeProspectPoolCampaignAssociation.bind(this, prospectPoolAssoc.frontendId)} icon><Icon name="trash" /></Button>
            </Form.Field>
          </Grid.Column>
        </Grid>
      );
    });
  }
  render () {
    return (
      <Grid>

        <Grid.Column width={16}>
          { this.renderProspectPoolCampaignAssociations() }
        </Grid.Column>

        <Grid.Column width={16}>
          <Button type="button"
            onClick={this.handleAddProspectPoolCampaignAssociationClick.bind(this)}
            icon="add"
            labelPosition="left"
            content={"Add Prospect Pool"}
          />
        </Grid.Column>
      </Grid>
    );
  }
}

class CampaignSearchAssociations extends React.Component {
  handleAddSearchAssocClick() {
    this.props.onChange([
      ...this.props.campaignSearchAssociations,
      { frontendId: uuidv1(), }
    ])
  }

  handleInputChange(id, event) {
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;

    let campaignSearchAssociations = [...this.props.campaignSearchAssociations]
    const toChange = campaignSearchAssociations.find(s => s.frontendId === id)
    toChange[name] = value
    this.props.onChange(campaignSearchAssociations)
  }

  handleSearchAssocSelectionChange(id, event, data) {
    let assocs = [...this.props.campaignSearchAssociations]
    const toChange = assocs.find(c => c.frontendId === id)
    toChange.searchId = this.props.searches.find(s => data.value == s.id).id
    this.props.onChange(assocs)
  }

  removeSearchAssoc(id) {
    let campaignSearchAssociations = [...this.props.campaignSearchAssociations]
    const filtered = campaignSearchAssociations.filter(s => s.frontendId !== id)
    this.props.onChange(filtered)
  }

  renderSearchAssocs() {
    if (!this.props.campaignSearchAssociations || this.props.campaignSearchAssociations.length == 0) {
      return (
        <div>
          <h3>No searches yet.</h3>
        </div>
      );
    }
    return this.props.campaignSearchAssociations.map(searchAssoc => {
      let queries = "-";
      if (present(searchAssoc)) {
        let search = this.props.searches.find(s => s.id === searchAssoc.searchId);
        if (present(search)) {
          queries = search.queries.map((q, i) => {
            return (
              <span key={i}>
                <a href={q.url} target="_blank">{q.description.replace(/\n/g, " AND ")}</a>&nbsp;||&nbsp;&nbsp;
              </span>
            );
          })
        }
      }
      return (
        <Grid columns="equal" key={searchAssoc.frontendId}>

          <Grid.Column>
            <Form.Field>
              <label>Search</label>
              <div style={{display: "flex"}}>
                <Dropdown
                  error={present(searchAssoc.errors)}
                  fluid
                  search
                  selection
                  options={this.props.searches.filter(s => present(s.id)).map(s => { return { key: s.id, value: s.id, text: s.name }})}
                  value={present(searchAssoc) ? searchAssoc.searchId : null}
                  onChange={this.handleSearchAssocSelectionChange.bind(this, searchAssoc.frontendId)}
                  placeholder='Select Search'
                />
              </div>
            </Form.Field>
            <div>
              <span>Queries: </span>&nbsp;
              {queries}
            </div>
          </Grid.Column>

          <Grid.Column width={1}>
            <Form.Field>
              <label>&nbsp;</label>
              <Button type="button" onClick={this.removeSearchAssoc.bind(this, searchAssoc.frontendId)} icon><Icon name="trash" /></Button>
            </Form.Field>
          </Grid.Column>
        </Grid>
      );
    });
  }
  render () {
    return (
      <Grid>

        <Grid.Column width={16}>
          { this.renderSearchAssocs() }
        </Grid.Column>

        <Grid.Column width={16}>
          <Button type="button"
            onClick={this.handleAddSearchAssocClick.bind(this)}
            icon="add"
            labelPosition="left"
            content={"Add Search"}
          />
        </Grid.Column>
      </Grid>
    );
  }
}

class Searches extends React.Component {
  handleAddSearchClick() {
    this.props.onChange([
      ...this.props.searches,
      { frontendId: uuidv1(), usesCsvImport: false, linkedInResultLimit: 2500, }
    ])
  }

  handleInputChange(id, event) {
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;

    let searches = [...this.props.searches]
    const toChange = searches.find(s => s.frontendId === id || s.id === id)
    toChange[name] = value
    this.props.onChange(searches)
  }

  handleRedoSearchClick(id) {
    let searches = [...this.props.searches]
    const toChange = searches.find(s => s.frontendId === id || s.id === id)
    toChange.shouldRedo = true
    this.props.onChange(searches)
    this.props.handleSubmit()
  }

  handleRedoAndClearSearchClick(id) {
    let searches = [...this.props.searches]
    const toChange = searches.find(s => s.frontendId === id || s.id === id)
    toChange.shouldRedo = true
    toChange.shouldClear = true
    this.props.onChange(searches)
    this.props.handleSubmit()
  }

  removeSearch(id) {
    let searches = [...this.props.searches]
    const filtered = searches.filter(s => s.frontendId !== id || s.id === id)
    this.props.onChange(filtered)
  }

  renderSearches() {
    if (!this.props.searches || this.props.searches.length == 0) {
      return (
        <div>
          <h3>No searches yet.</h3>
        </div>
      );
    }
    return this.props.searches.map(search => {
      let onChange = (event) => {this.handleInputChange(search.frontendId, event)}
      onChange = onChange.bind(this)
      return (
        <Segment key={search.frontendId} data-test-id="search-form">
          <Form>
            <Grid columns="equal" >

              <Grid.Row>
                <Grid.Column width={12}>
                  { formInput(search, "name", "Name", onChange) }
                </Grid.Column>
                <Grid.Column width={3}>
                  <Form.Field>
                    <label>&nbsp;</label>
                    { formInput(search, "usesCsvImport", "CSV?", onChange, Form.Checkbox,  ) }
                  </Form.Field>
                </Grid.Column>
                { !search.id &&
                    <Grid.Column width={1}>
                      <Form.Field>
                        <label>&nbsp;</label>
                        <Button type="button" onClick={this.removeSearch.bind(this, search.frontendId)} icon><Icon name="trash" /></Button>
                      </Form.Field>
                    </Grid.Column>
                }
              </Grid.Row>

              { search.usesCsvImport && <React.Fragment>
                <Grid.Column>
                  { formInput(search, "searchResultCsvUrl", "Search Result CSV URL", onChange) }
                </Grid.Column>

              </React.Fragment>
              }
              { !search.usesCsvImport && <React.Fragment>
                <Grid.Column width="16">
                  { formInput(search, "linkedInSearchUrl", "Sales Navigator Search URL", onChange, Form.TextArea, {style: { minHeight: 120 }},) }
                </Grid.Column>
                <Grid.Column width="5">
                  { formInput(search, "linkedInResultLimit", "Result Limit", onChange) }
                </Grid.Column>
                <LinkedInAccountSelectionAndForm
                  linkedInAccounts={this.props.linkedInAccounts}
                  onLinkedInAccountsChange={this.props.onLinkedInAccountsChange}
                  onLinkedInAccountSelectionChange={onChange}
                  selectedLinkedInAccountId={search.linkedInAccountId}
                  selectionError={errorFor(search, "linkedInAccount")}
                />

            </React.Fragment>
              }
              <Grid.Column width={16}>
                Status: {search.status || "-"} &nbsp; &nbsp;
                { (!search.usesCsvImport && present(search.id)) && <Button loading={this.props.loading} size="mini" onClick={this.handleRedoSearchClick.bind(this, search.id)}>Redo &amp; Add</Button> }
                { (!search.usesCsvImport && present(search.id)) && <Button loading={this.props.loading} size="mini" onClick={this.handleRedoAndClearSearchClick.bind(this, search.id)}>Redo &amp; Overwrite</Button> }
                <br />
                <b>Total (after blacklist)</b>: {search.numProspects-search.numBlacklistedProspects || 0} &nbsp; &nbsp;
                <b>Left</b>: {search.numLeftProspects || 0} &nbsp; &nbsp;
                <b>Blacklisted</b>: {search.numBlacklistedProspects || 0} &nbsp; &nbsp;
                <b>Errors:</b> {search.numConnectionErrors || 0} ({search.numConnectionErrorsAfterDeadlineWhereErrorsCount} after deadline) &nbsp;&nbsp;
                <br />
                <b>Requested:&nbsp;</b>
                <SwitchPercentageAbsolute
                  aria-label={"Requested"}
                  part={search.numDelivered}
                  full={search.nextMilestone}
                  style={{display: "inline-block", width: "auto", height: "auto", }}
                />&nbsp; &nbsp;
                <b>Connected:&nbsp;</b>
                <SwitchPercentageAbsolute
                  aria-label={"Connected"}
                  part={search.numAccepted}
                  full={search.numDelivered}
                  style={{display: "inline-block", width: "auto", height: "auto", }}
                />&nbsp; &nbsp;
                <b>Responded:&nbsp;</b>
                <SwitchPercentageAbsolute
                  aria-label={"Responded"}
                  part={search.numAnswered}
                  full={search.numAccepted}
                  style={{display: "inline-block", width: "auto", height: "auto", }}
                />&nbsp; &nbsp;
                <b>Conversion:&nbsp;</b>
                <SwitchPercentageAbsolute
                  aria-label={"Conversion"}
                  part={search.numAnswered}
                  full={search.numDelivered}
                  style={{display: "inline-block", width: "auto", height: "auto", }}
                />&nbsp; &nbsp;
                <a href={`/backend/searches/${search.id}`}>More...</a>


              <br />
              Queries:&nbsp;
              { present(search.queries) ? search.queries.map((q, i) => {
                return (
                  <span key={i}>
                    <a href={q.url} target="_blank">{q.description.replace(/\n/g, " AND ")}</a>&nbsp;||&nbsp;&nbsp;
                  </span>
                );
              }) : "-"
              }
            </Grid.Column>
          </Grid>
        </Form>
      </Segment>
      );
    });
  }
  render () {
    return (
      <Grid>
        <Grid.Column width={16}>
          { this.renderSearches() }
        </Grid.Column>
        <Grid.Column width={5} floated="left">
          <Button type="button"
            onClick={this.handleAddSearchClick.bind(this)}
            icon="add"
            labelPosition="left"
            content={"Add Search"}
          />
        </Grid.Column>
        <Grid.Column width={5} floated="right">
          <Button type="button" onClick={this.props.handleSubmit} loading={this.props.loading} positive floated="right">Save</Button>
        </Grid.Column>
      </Grid>
    );
  }
}

function present(x) {
  if (typeof x === "object" && _.isEmpty(x)) return false;
  if (Array.isArray(x) && x.length == 0) return false;
  if (typeof x === "undefined" || !x || (typeof x === "String" && x.trim() == "") || x == null) return false;
  return true;
}

function errorFor(model, columnName) {
  if (present(model) && present(model.errors) && present(model.errors[columnName])) {
    return model.errors[columnName].join(", ")
  }
  return null;
}

function formInput(model, name, label, onChange, Element = Form.Input, props) {
  let valueProp = { value: model[name] || "" }
  if (Element == Form.Checkbox) {
    valueProp = { checked: model[name] }
  }
  return (
    <Element
      error={errorFor(model, name)}
      label={label}
      {...valueProp}
      onChange={adaptOnChangeToClassicFormOnChange(onChange)}
      name={name}
      {...props}
    />
  );
}
function adaptOnChangeToClassicFormOnChange(formOnChange) {
  return (_, data) => { return formOnChange( { target: {...data} } ) };
}

